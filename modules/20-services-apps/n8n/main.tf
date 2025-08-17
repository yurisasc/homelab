terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

variable "image_tag" {
  description = "The tag for the n8n container image"
  type        = string
  default     = "latest"
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

module "system_globals" {
  source = "../../00-globals/system"
}

locals {
  container_name    = "n8n"
  database_name     = "n8n-postgres"
  redis_name        = "n8n-redis"
  n8n_image         = "docker.n8n.io/n8nio/n8n"
  database_image    = "postgres"
  redis_image       = "redis"
  n8n_tag           = var.image_tag != "" ? var.image_tag : "latest"
  database_tag      = "16"
  redis_tag         = "7-alpine"
  monitoring        = true
  env_file          = "${path.module}/.env"
  n8n_internal_port = 5678

  # Define volumes
  n8n_volumes = [
    {
      host_path      = "${var.volume_path}/n8n_storage/_data"
      container_path = "/home/node/.n8n"
      read_only      = false
    }
  ]

  database_volumes = [
    {
      host_path      = "${var.volume_path}/db_storage/_data"
      container_path = "/var/lib/postgresql/data"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/init-data.sh"
      container_path = "/docker-entrypoint-initdb.d/init-data.sh"
      read_only      = false
    }
  ]

  # Environment variables for the database
  database_env_vars = {
    POSTGRES_USER              = provider::dotenv::get_by_key("POSTGRES_USER", local.env_file)
    POSTGRES_PASSWORD          = provider::dotenv::get_by_key("POSTGRES_PASSWORD", local.env_file)
    POSTGRES_DB                = provider::dotenv::get_by_key("POSTGRES_DB", local.env_file)
    POSTGRES_NON_ROOT_USER     = provider::dotenv::get_by_key("POSTGRES_NON_ROOT_USER", local.env_file)
    POSTGRES_NON_ROOT_PASSWORD = provider::dotenv::get_by_key("POSTGRES_NON_ROOT_PASSWORD", local.env_file)
  }

  # Environment variables for n8n
  n8n_env_vars = {
    DB_TYPE                      = "postgresdb"
    DB_POSTGRESDB_HOST           = local.database_name
    DB_POSTGRESDB_PORT           = 5432
    DB_POSTGRESDB_DATABASE       = provider::dotenv::get_by_key("POSTGRES_DB", local.env_file)
    DB_POSTGRESDB_USER           = provider::dotenv::get_by_key("POSTGRES_NON_ROOT_USER", local.env_file)
    DB_POSTGRESDB_PASSWORD       = provider::dotenv::get_by_key("POSTGRES_NON_ROOT_PASSWORD", local.env_file)
    N8N_HOST                     = provider::dotenv::get_by_key("N8N_HOST", local.env_file)
    N8N_PORT                     = provider::dotenv::get_by_key("N8N_PORT", local.env_file)
    N8N_PROTOCOL                 = provider::dotenv::get_by_key("N8N_PROTOCOL", local.env_file)
    WEBHOOK_URL                  = provider::dotenv::get_by_key("WEBHOOK_URL", local.env_file)
    NODE_FUNCTION_ALLOW_EXTERNAL = provider::dotenv::get_by_key("NODE_FUNCTION_ALLOW_EXTERNAL", local.env_file)
    GENERIC_TIMEZONE             = module.system_globals.timezone
    QUEUE_BULL_REDIS_HOST        = local.redis_name
    QUEUE_BULL_REDIS_PORT        = 6379
    QUEUE_BULL_REDIS_USERNAME    = "redis"
    QUEUE_BULL_REDIS_PASSWORD    = "redis"
  }

  # Healthcheck configuration for the database
  database_healthcheck = {
    test         = ["CMD-SHELL", "pg_isready -h localhost -U $${POSTGRES_USER} -d $${POSTGRES_DB}"]
    interval     = "5s"
    timeout      = "5s"
    retries      = 10
    start_period = "10s"
  }

  # Healthcheck configuration for Redis
  redis_healthcheck = {
    test         = ["CMD-SHELL", "redis-cli ping"]
    interval     = "5s"
    timeout      = "5s"
    retries      = 10
    start_period = "10s"
  }

  # Define Redis volume
  redis_volumes = [
    {
      host_path      = "${var.volume_path}/redis_data"
      container_path = "/data"
      read_only      = false
    }
  ]

  n8n_mcp_container_name = "n8n-mcp"
  n8n_mcp_image          = "ghcr.io/czlonkowski/n8n-mcp"
  n8n_mcp_tag            = "latest"
  n8n_mcp_internal_port  = 3000

  n8n_mcp_volumes = [
    {
      host_path      = "${var.volume_path}/n8n_mcp_storage/_data"
      container_path = "/app/data"
      read_only      = false
    }
  ]

  n8n_mcp_env_vars = {
    MCP_MODE         = "http"
    USE_FIXED_HTTP   = "true"
    AUTH_TOKEN       = provider::dotenv::get_by_key("N8N_MCP_AUTH_TOKEN", local.env_file)
    N8N_API_URL      = "http://${local.container_name}:${local.n8n_internal_port}"
    N8N_API_KEY      = provider::dotenv::get_by_key("N8N_API_KEY", local.env_file)
    NODE_ENV         = "production"
    LOG_LEVEL        = "info"
    PORT             = local.n8n_mcp_internal_port
    NODE_DB_PATH     = "/app/data/nodes.db"
    REBUILD_ON_START = "false"
    GENERIC_TIMEZONE = module.system_globals.timezone
  }

  n8n_mcp_healthcheck = {
    test         = ["CMD", "curl", "-f", "http://127.0.0.1:${local.n8n_mcp_internal_port}/health"]
    interval     = "30s"
    timeout      = "10s"
    retries      = 3
    start_period = "40s"
  }
}

module "n8n_network" {
  source = "../../01-networking/docker-network"
  name   = "n8n-network"
  driver = "bridge"
  subnet = "172.24.0.0/16"
}

# Create the PostgreSQL container
module "postgres" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.database_name
  image          = local.database_image
  tag            = local.database_tag
  volumes        = local.database_volumes
  user           = "1000:1000"
  env_vars       = local.database_env_vars
  networks       = [module.n8n_network.name]
  monitoring     = local.monitoring
  healthcheck    = local.database_healthcheck
}

# Create the Redis container
module "redis" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.redis_name
  image          = local.redis_image
  tag            = local.redis_tag
  volumes        = local.redis_volumes
  user           = "1000:1000"
  env_vars = {
    REDIS_USERNAME = "redis"
    REDIS_PASSWORD = "redis"
  }
  networks    = [module.n8n_network.name]
  monitoring  = local.monitoring
  command     = ["redis-server", "--requirepass", "redis", "--user", "redis", "on", ">redis", "~*", "+@all"]
  healthcheck = local.redis_healthcheck
}

# Create the n8n container
module "n8n" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.container_name
  image          = local.n8n_image
  tag            = local.n8n_tag
  volumes        = local.n8n_volumes
  user           = "1000:1000"
  env_vars       = local.n8n_env_vars
  networks       = concat([module.n8n_network.name], var.networks)
  monitoring     = local.monitoring
  depends_on     = [module.postgres, module.redis]
}

# Create the n8n-mcp container
module "n8n_mcp" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.n8n_mcp_container_name
  image          = local.n8n_mcp_image
  tag            = local.n8n_mcp_tag
  volumes        = local.n8n_mcp_volumes
  user           = "1000:1000"
  env_vars       = local.n8n_mcp_env_vars
  networks       = concat([module.n8n_network.name], var.networks)
  monitoring     = local.monitoring
  healthcheck    = local.n8n_mcp_healthcheck
  depends_on     = [module.n8n]
}

output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = local.n8n_internal_port
    endpoint     = "http://${local.container_name}:${local.n8n_internal_port}"
    subdomains   = ["n8n"]
    publish_via  = "tunnel"
  }
}

output "n8n_mcp_service_definition" {
  description = "General service definition with optional ingress configuration for n8n-mcp"
  value = {
    name         = local.n8n_mcp_container_name
    primary_port = local.n8n_mcp_internal_port
    endpoint     = "http://${local.n8n_mcp_container_name}:${local.n8n_mcp_internal_port}"
    subdomains   = ["n8n-mcp"]
    publish_via  = "tunnel"
  }
}
