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

locals {
  container_name  = "n8n"
  database_name   = "n8n-postgres"
  n8n_image       = "docker.n8n.io/n8nio/n8n"
  database_image  = "postgres"
  n8n_tag         = var.image_tag != "" ? var.image_tag : "latest"
  database_tag    = "16"
  monitoring      = true
  env_file        = "${path.module}/.env"
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
    POSTGRES_USER            = provider::dotenv::get_by_key("POSTGRES_USER", local.env_file)
    POSTGRES_PASSWORD        = provider::dotenv::get_by_key("POSTGRES_PASSWORD", local.env_file)
    POSTGRES_DB              = provider::dotenv::get_by_key("POSTGRES_DB", local.env_file)
    POSTGRES_NON_ROOT_USER   = provider::dotenv::get_by_key("POSTGRES_NON_ROOT_USER", local.env_file)
    POSTGRES_NON_ROOT_PASSWORD = provider::dotenv::get_by_key("POSTGRES_NON_ROOT_PASSWORD", local.env_file)
  }
  
  # Environment variables for n8n
  n8n_env_vars = {
    DB_TYPE                       = "postgresdb"
    DB_POSTGRESDB_HOST            = local.database_name
    DB_POSTGRESDB_PORT            = 5432
    DB_POSTGRESDB_DATABASE        = provider::dotenv::get_by_key("POSTGRES_DB", local.env_file)
    DB_POSTGRESDB_USER            = provider::dotenv::get_by_key("POSTGRES_NON_ROOT_USER", local.env_file)
    DB_POSTGRESDB_PASSWORD        = provider::dotenv::get_by_key("POSTGRES_NON_ROOT_PASSWORD", local.env_file)
    N8N_HOST                      = provider::dotenv::get_by_key("N8N_HOST", local.env_file)
    N8N_PORT                      = provider::dotenv::get_by_key("N8N_PORT", local.env_file)
    N8N_PROTOCOL                  = provider::dotenv::get_by_key("N8N_PROTOCOL", local.env_file)
    WEBHOOK_URL                   = provider::dotenv::get_by_key("WEBHOOK_URL", local.env_file)
    NODE_FUNCTION_ALLOW_EXTERNAL  = provider::dotenv::get_by_key("NODE_FUNCTION_ALLOW_EXTERNAL", local.env_file)
  }

  # Healthcheck configuration for the database
  database_healthcheck = {
    test         = ["CMD-SHELL", "pg_isready -h localhost -U $${POSTGRES_USER} -d $${POSTGRES_DB}"]
    interval     = "5s"
    timeout      = "5s"
    retries      = 10
    start_period = "10s"
  }
}

module "n8n_network" {
  source = "../../01-networking/docker-network"
  name   = "n8n-network"
  driver = "bridge"
}

# Create the PostgreSQL container
module "postgres" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.database_name
  image          = local.database_image
  tag            = local.database_tag
  volumes        = local.database_volumes
  env_vars       = local.database_env_vars
  networks       = [module.n8n_network.name]
  monitoring     = local.monitoring
  healthcheck    = local.database_healthcheck
}

# Create the n8n container
module "n8n" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.container_name
  image          = local.n8n_image
  tag            = local.n8n_tag
  volumes        = local.n8n_volumes
  env_vars       = local.n8n_env_vars
  networks       = concat([module.n8n_network.name], var.networks)
  monitoring     = local.monitoring
  depends_on     = [module.postgres]
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
