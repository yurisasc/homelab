terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

variable "image_tag" {
  description = "The tag for the Immich container images (server and machine-learning)"
  type        = string
  default     = "release"
}

variable "appdata_path" {
  description = "Base directory for Immich app data"
  type        = string
}

variable "library_path" {
  description = "Base directory for Immich library data"
  type        = string
}

variable "networks" {
  description = "List of networks to which the Immich server should be attached (in addition to the module network)"
  type        = list(string)
  default     = []
}

locals {
  env_file   = "${path.module}/.env"
  monitoring = true

  # Container names
  server_name   = "immich-server"
  ml_name       = "immich-machine-learning"
  redis_name    = "immich-redis"
  postgres_name = "immich-postgres"

  # Images and tags
  server_image   = "ghcr.io/immich-app/immich-server"
  ml_image       = "ghcr.io/immich-app/immich-machine-learning"
  redis_image    = "docker.io/valkey/valkey"
  postgres_image = "ghcr.io/immich-app/postgres"

  server_tag   = var.image_tag
  ml_tag       = var.image_tag
  redis_tag    = "8-bookworm"
  postgres_tag = "14-vectorchord0.4.3-pgvectors0.2.0"

  # Ports
  server_port = 2283
  ml_port     = 3003

  # Volumes (host paths)
  server_volumes = [
    {
      host_path      = "${var.library_path}/data"
      container_path = "/data"
      read_only      = false
    }
  ]

  ml_volumes = [
    {
      host_path      = "${var.library_path}/ml/cache"
      container_path = "/cache"
      read_only      = false
    }
  ]

  postgres_volumes = [
    {
      host_path      = "${var.appdata_path}/postgres/pgdata"
      container_path = "/var/lib/postgresql/data"
      read_only      = false
    }
  ]

  # Environment variables for Postgres
  postgres_env_vars = {
    POSTGRES_USER        = provider::dotenv::get_by_key("DB_USERNAME", local.env_file)
    POSTGRES_PASSWORD    = provider::dotenv::get_by_key("DB_PASSWORD", local.env_file)
    POSTGRES_DB          = provider::dotenv::get_by_key("DB_DATABASE_NAME", local.env_file)
    POSTGRES_INITDB_ARGS = "--data-checksums"
  }

  # Environment variables for Immich server
  server_env_vars = {
    # Database
    DB_HOSTNAME      = local.postgres_name
    DB_PORT          = "5432"
    DB_USERNAME      = provider::dotenv::get_by_key("DB_USERNAME", local.env_file)
    DB_PASSWORD      = provider::dotenv::get_by_key("DB_PASSWORD", local.env_file)
    DB_DATABASE_NAME = provider::dotenv::get_by_key("DB_DATABASE_NAME", local.env_file)

    # Redis
    REDIS_HOSTNAME = local.redis_name
    REDIS_PORT     = "6379"
    REDIS_DBINDEX  = "0"

    # General
    IMMICH_MEDIA_LOCATION = "/data"
  }

  # Healthchecks
  redis_healthcheck = {
    test         = ["CMD", "redis-cli", "ping"]
    interval     = "10s"
    timeout      = "5s"
    retries      = 5
    start_period = "5s"
  }

  postgres_healthcheck = {
    test         = ["CMD", "pg_isready", "-U", provider::dotenv::get_by_key("DB_USERNAME", local.env_file), "-d", provider::dotenv::get_by_key("DB_DATABASE_NAME", local.env_file)]
    interval     = "10s"
    timeout      = "5s"
    retries      = 5
    start_period = "5s"
  }
}

# Dedicated network for Immich
module "immich_network" {
  source = "../../01-networking/docker-network"
  name   = "immich-network"
  driver = "bridge"
}

# Valkey (Redis) service
module "redis" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.redis_name
  image          = local.redis_image
  tag            = local.redis_tag
  networks       = [module.immich_network.name]
  monitoring     = local.monitoring
  healthcheck    = local.redis_healthcheck
}

# Postgres service (Immich custom image)
module "postgres" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.postgres_name
  image          = local.postgres_image
  tag            = local.postgres_tag
  volumes        = local.postgres_volumes
  env_vars       = local.postgres_env_vars
  networks       = [module.immich_network.name]
  monitoring     = local.monitoring
  healthcheck    = local.postgres_healthcheck
}

# Immich Machine Learning service
module "machine_learning" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.ml_name
  image          = local.ml_image
  tag            = local.ml_tag
  volumes        = local.ml_volumes
  networks       = [module.immich_network.name]
  monitoring     = local.monitoring
}

# Immich Server service
module "immich" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.server_name
  image          = local.server_image
  tag            = local.server_tag
  ports = [
    {
      internal = local.server_port
      external = local.server_port
      protocol = "tcp"
    }
  ]
  volumes    = local.server_volumes
  env_vars   = local.server_env_vars
  networks   = concat([module.immich_network.name], var.networks)
  monitoring = local.monitoring
  depends_on = [module.postgres, module.redis]
}

output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.server_name
    primary_port = local.server_port
    endpoint     = "http://${local.server_name}:${local.server_port}"
    subdomains   = ["photos"]
    publish_via  = "reverse_proxy"
    proxied      = false
  }
}
