terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

variable "image_tag" {
  description = "The tag for the affine container image"
  type        = string
  default     = "stable"
}

variable "volume_path" {
  description = "Base directory for volumes"
  type        = string
}

variable "networks" {
  description = "List of networks to which the container should be attached"
  type        = list(string)
  default     = []
}

variable "backup_networks" {
  description = "List of networks for backup access to database"
  type        = list(string)
  default     = []
}

module "smtp" {
  source = "../../00-globals/smtp"
}

locals {
  container_name       = "affine-server"
  migration_name       = "affine-migration-job"
  redis_name           = "affine-redis"
  postgres_name        = "affine-postgres"
  indexer_name         = "affine-indexer"
  affine_image         = "ghcr.io/yurisasc/affine"
  postgres_image       = "pgvector/pgvector"
  redis_image          = "redis"
  indexer_image        = "manticoresearch/manticore"
  affine_tag           = provider::dotenv::get_by_key("AFFINE_REVISION", local.env_file)
  postgres_tag         = "pg16"
  redis_tag            = "latest"
  manticore_tag        = try(provider::dotenv::get_by_key("MANTICORE_VERSION", local.env_file), "10.1.0")
  env_file             = "${path.module}/.env"
  affine_internal_port = 3010

  # Define volumes
  affine_volumes = [
    {
      host_path      = "${var.volume_path}/self-host/storage"
      container_path = "/root/.affine/storage"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/self-host/config"
      container_path = "/root/.affine/config"
      read_only      = false
    }
  ]

  migration_volumes = [
    {
      host_path      = "${var.volume_path}/self-host/storage"
      container_path = "/root/.affine/storage"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/self-host/config"
      container_path = "/root/.affine/config"
      read_only      = false
    }
  ]

  postgres_volumes = [
    {
      host_path      = "${var.volume_path}/self-host/postgres/pgdata"
      container_path = "/var/lib/postgresql/data"
      read_only      = false
    }
  ]

  # Manticore indexer data volume
  indexer_volumes = [
    {
      host_path      = "${var.volume_path}/self-host/manticore"
      container_path = "/var/lib/manticore"
      read_only      = false
    }
  ]

  # Environment variables for postgres
  postgres_env_vars = {
    POSTGRES_USER             = provider::dotenv::get_by_key("DB_USERNAME", local.env_file)
    POSTGRES_PASSWORD         = provider::dotenv::get_by_key("DB_PASSWORD", local.env_file)
    POSTGRES_DB               = provider::dotenv::get_by_key("DB_DATABASE", local.env_file)
    POSTGRES_INITDB_ARGS      = "--data-checksums"
    POSTGRES_HOST_AUTH_METHOD = "trust"
  }

  # Environment variables for AFFiNE
  affine_env_vars = {
    REDIS_SERVER_HOST                   = local.redis_name
    DATABASE_URL                        = "postgresql://${provider::dotenv::get_by_key("DB_USERNAME", local.env_file)}:${provider::dotenv::get_by_key("DB_PASSWORD", local.env_file)}@${local.postgres_name}:5432/${provider::dotenv::get_by_key("DB_DATABASE", local.env_file)}"
    AFFINE_INDEXER_ENABLED              = "true"
    AFFINE_INDEXER_SEARCH_ENDPOINT      = "http://${local.indexer_name}:9308"
    AFFINE_SERVER_HTTPS                 = provider::dotenv::get_by_key("AFFINE_SERVER_HTTPS", local.env_file)
    AFFINE_SERVER_HOST                  = provider::dotenv::get_by_key("AFFINE_SERVER_HOST", local.env_file)
    AFFINE_SERVER_NAME                  = provider::dotenv::get_by_key("AFFINE_SERVER_NAME", local.env_file)
    PORT                                = provider::dotenv::get_by_key("PORT", local.env_file)
    DB_USERNAME                         = provider::dotenv::get_by_key("DB_USERNAME", local.env_file)
    DB_PASSWORD                         = provider::dotenv::get_by_key("DB_PASSWORD", local.env_file)
    DB_DATABASE                         = provider::dotenv::get_by_key("DB_DATABASE", local.env_file)
    MAILER_HOST                         = module.smtp.mail_host
    MAILER_PORT                         = module.smtp.mail_port
    MAILER_USER                         = module.smtp.mail_username
    MAILER_PASSWORD                     = module.smtp.mail_password
    R2_OBJECT_STORAGE_ACCOUNT_ID        = provider::dotenv::get_by_key("R2_OBJECT_STORAGE_ACCOUNT_ID", local.env_file)
    R2_OBJECT_STORAGE_ACCESS_KEY_ID     = provider::dotenv::get_by_key("R2_OBJECT_STORAGE_ACCESS_KEY_ID", local.env_file)
    R2_OBJECT_STORAGE_SECRET_ACCESS_KEY = provider::dotenv::get_by_key("R2_OBJECT_STORAGE_SECRET_ACCESS_KEY", local.env_file)
  }

  # Healthcheck configuration for Redis
  redis_healthcheck = {
    test         = ["CMD", "redis-cli", "--raw", "incr", "ping"]
    interval     = "10s"
    timeout      = "5s"
    retries      = 5
    start_period = "5s"
  }

  # Healthcheck configuration for Postgres
  postgres_healthcheck = {
    test         = ["CMD", "pg_isready", "-U", provider::dotenv::get_by_key("DB_USERNAME", local.env_file), "-d", provider::dotenv::get_by_key("DB_DATABASE", local.env_file)]
    interval     = "10s"
    timeout      = "5s"
    retries      = 5
    start_period = "5s"
  }

  # Healthcheck configuration for Manticore indexer
  indexer_healthcheck = {
    test         = ["CMD", "wget", "-O-", "http://127.0.0.1:9308"]
    interval     = "10s"
    timeout      = "5s"
    retries      = 5
    start_period = "5s"
  }
}

module "affine_network" {
  source = "../../01-networking/docker-network"
  name   = "affine-network"
  subnet = "11.100.0.0/16"
  driver = "bridge"
}

# Create the Redis container
module "redis" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.redis_name
  image          = local.redis_image
  tag            = local.redis_tag
  networks       = [module.affine_network.name]
  healthcheck    = local.redis_healthcheck
}

# Create the PostgreSQL container
module "postgres" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.postgres_name
  image          = local.postgres_image
  tag            = local.postgres_tag
  volumes        = local.postgres_volumes
  env_vars       = local.postgres_env_vars
  networks       = concat([module.affine_network.name], var.backup_networks)
  healthcheck    = local.postgres_healthcheck
}

# Create the Manticore indexer container
module "indexer" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.indexer_name
  image          = local.indexer_image
  tag            = local.manticore_tag
  volumes        = local.indexer_volumes
  networks       = [module.affine_network.name]
  healthcheck    = local.indexer_healthcheck
}

# Create the migration job container
module "migration" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.migration_name
  image          = local.affine_image
  tag            = local.affine_tag
  volumes        = local.migration_volumes
  env_vars       = local.affine_env_vars
  command        = ["sh", "-c", "node ./scripts/self-host-predeploy.js"]
  networks       = [module.affine_network.name]
  depends_on     = [module.postgres, module.redis]
  restart_policy = "no"
}

# Create the affine container
module "affine" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.container_name
  image          = local.affine_image
  tag            = local.affine_tag
  volumes        = local.affine_volumes
  env_vars       = local.affine_env_vars
  networks       = concat([module.affine_network.name], var.networks)
  depends_on     = [module.postgres, module.redis, module.migration, module.indexer]
}

output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = local.affine_internal_port
    endpoint     = "http://${local.container_name}:${local.affine_internal_port}"
    subdomains   = ["notes"]
    publish_via  = "reverse_proxy"
    proxied      = false
  }
}

output "db_backup_config" {
  description = "Database backup configuration for Affine"
  value = {
    name         = "affine"
    type         = "postgres"
    host         = local.postgres_name
    port         = 5432
    database     = provider::dotenv::get_by_key("DB_DATABASE", local.env_file)
    username     = provider::dotenv::get_by_key("DB_USERNAME", local.env_file)
    password_env = "DB_PASSWORD"   # Env var name in Affine .env
    env_file     = local.env_file   # Path to Affine .env file
  }
}
