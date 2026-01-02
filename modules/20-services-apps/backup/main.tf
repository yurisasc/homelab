terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

variable "db_configs" {
  description = "List of database backup configurations from services"
  type = list(object({
    name         = string
    type         = string
    host         = string
    port         = optional(number)
    database     = string
    username     = string
    password_env = string
    env_file     = string  # Path to service's .env file
  }))
  default = []
}

variable "networks" {
  description = "Docker networks to attach backup job container to"
  type        = list(string)
  default     = []
}

module "system_globals" {
  source = "../../00-globals/system"
}

locals {
  env_file = "${path.module}/.env"

  # Normalize DB configs: assign a unique password env var name inside the
  # backup container for each database, while still reading the secret from
  # the per-service .env file using the original password_env key.
  db_registry_full = [
    for db in var.db_configs : {
      name     = db.name
      type     = db.type
      host     = db.host
      port     = db.port
      database = db.database
      username = db.username

      # Env var name used *inside the backup container* for this DB password.
      password_env = "BACKUP_DB_PASSWORD_${db.name}"

      # Source for the password value: env var key + .env file path from the service.
      source_password_env = db.password_env
      env_file            = db.env_file
    }
  ]

  # JSON registry passed to the backup container (no env_file or source_password_env)
  db_registry_json = jsonencode([
    for db in local.db_registry_full : {
      name         = db.name
      type         = db.type
      host         = db.host
      port         = db.port
      database     = db.database
      username     = db.username
      password_env = db.password_env
    }
  ])

  # Read each password from its service's .env file and expose it under the
  # container-specific env var name (e.g. BACKUP_DB_PASSWORD_immich).
  password_env_vars = {
    for db in local.db_registry_full :
    db.password_env => provider::dotenv::get_by_key(db.source_password_env, db.env_file)
  }

  # Core backup configuration from backup module .env
  backup_dump_dir = provider::dotenv::get_by_key("BACKUP_DUMP_DIR", local.env_file)

  # Read backup sets from JSON file (separate file to avoid dotenv multi-line parsing issues)
  backup_sets_file = "${path.module}/backup-sets.json"
  backup_sets      = fileexists(local.backup_sets_file) ? jsondecode(file(local.backup_sets_file)) : []
  backup_sets_json = jsonencode(local.backup_sets)
  backup_include_paths = distinct(flatten([
    for set in local.backup_sets : set.paths
  ]))

  # Volumes: all paths from backup sets (auto-derived)
  backup_volumes = [
    for p in local.backup_include_paths : {
      host_path      = p
      container_path = p
      read_only      = true
    }
  ]

  # Dedicated read-write volume for BACKUP_DUMP_DIR so the container can
  # create and write dump files, while other include paths remain read-only.
  dump_volume = local.backup_dump_dir != "" ? {
    host_path      = abspath(local.backup_dump_dir)
    container_path = local.backup_dump_dir
    read_only      = false
  } : null

  # Mount scripts directory into the container
  scripts_volume = {
    # Use abspath() to guarantee an absolute host path for the Docker provider
    host_path      = abspath("${path.module}/scripts")
    container_path = "/scripts"
    read_only      = false
  }

  all_volumes = concat(
    local.backup_volumes,
    local.dump_volume != null ? [local.dump_volume] : [],
    [local.scripts_volume],
  )

  # Restic configuration
  env_vars_base = {
    BACKUP_DB_REGISTRY         = local.db_registry_json
    BACKUP_SETS_JSON           = local.backup_sets_json
    BACKUP_DUMP_DIR            = local.backup_dump_dir
    BACKUP_DUMP_RETENTION_DAYS = provider::dotenv::get_by_key("BACKUP_DUMP_RETENTION_DAYS", local.env_file)
    BACKUP_SCHEDULE_HOUR       = provider::dotenv::get_by_key("BACKUP_SCHEDULE_HOUR", local.env_file)
    BACKUP_DRY_RUN             = provider::dotenv::get_by_key("BACKUP_DRY_RUN", local.env_file)
    RESTIC_REPOSITORY          = provider::dotenv::get_by_key("RESTIC_REPOSITORY", local.env_file)
    RESTIC_PASSWORD            = provider::dotenv::get_by_key("RESTIC_PASSWORD", local.env_file)
    B2_ACCOUNT_ID              = provider::dotenv::get_by_key("B2_ACCOUNT_ID", local.env_file)
    B2_ACCOUNT_KEY             = provider::dotenv::get_by_key("B2_ACCOUNT_KEY", local.env_file)
    B2_BUCKET                  = provider::dotenv::get_by_key("B2_BUCKET", local.env_file)
  }

  # Merge DB passwords (keys are env var names)
  env_vars = merge(local.env_vars_base, local.password_env_vars)

  # Healthcheck: consider container healthy if either no DBs are configured
  # or we have at least one recent dump file in BACKUP_DUMP_DIR (last 2 days).
  backup_healthcheck = {
    test         = [
      "CMD-SHELL",
      "[[ -z \"$${BACKUP_DB_REGISTRY}\" ]] || find \"$${BACKUP_DUMP_DIR}\" -type f -name '*.sql.gz' -mtime -2 | grep -q ."
    ]
    interval     = "5m"
    timeout      = "30s"
    retries      = 3
    start_period = "10m"
  }
}

module "backup_job" {
  source         = "../../10-services-generic/docker-service"
  container_name = "homelab-backup"
  image          = "ubuntu"
  tag            = "22.04"

  volumes  = local.all_volumes
  env_vars = local.env_vars
  networks = var.networks

  # Install required tools and start the backup scheduler
  # PostgreSQL 16 client is installed from official repo for compatibility with pg 15/16 servers
  command = [
    "bash",
    "-c",
    <<-EOT
      apt-get update && \
      apt-get install -y --no-install-recommends curl ca-certificates gnupg bzip2 pv && \
      curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql.gpg && \
      echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt jammy-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
      apt-get update && \
      apt-get install -y --no-install-recommends postgresql-client-16 mariadb-client jq && \
      curl -L https://github.com/restic/restic/releases/download/v0.17.3/restic_0.17.3_linux_amd64.bz2 | bunzip2 > /usr/local/bin/restic && \
      chmod +x /usr/local/bin/restic && \
      chmod +x /scripts/*.sh && \
      /scripts/backup.sh
    EOT
  ]

  monitoring  = true
  healthcheck = local.backup_healthcheck
}

output "container_name" {
  description = "Name of the backup job container"
  value       = module.backup_job.container_name
}
