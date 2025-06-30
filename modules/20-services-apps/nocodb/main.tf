terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

variable "image_tag" {
  description = "Tag of the NocoDB image to use"
  type        = string
  default     = "latest"
}

variable "postgres_image_tag" {
  description = "Tag of the Postgres image to use"
  type        = string
  default     = "16.6"
}

variable "volume_path" {
  description = "Host path for NocoDB data volumes"
  type        = string
}

variable "networks" {
  description = "List of networks to which the containers should be attached"
  type        = list(string)
  default     = []
}

locals {
  container_name       = "nocodb"
  postgres_name        = "nocodb-postgres"
  nocodb_image         = "nocodb/nocodb"
  postgres_image       = "postgres"
  nocodb_tag           = var.image_tag
  postgres_tag         = var.postgres_image_tag
  monitoring           = true
  nocodb_internal_port = 8080
  env_file             = "${path.module}/.env"
  postgres_user        = provider::dotenv::get_by_key("DB_USERNAME", local.env_file)
  postgres_password    = provider::dotenv::get_by_key("DB_PASSWORD", local.env_file)
  postgres_db          = provider::dotenv::get_by_key("DB_DATABASE", local.env_file)
  
  # Define volumes
  nocodb_volumes = [
    {
      host_path      = "${var.volume_path}/data"
      container_path = "/usr/app/data"
      read_only      = false
    }
  ]
  
  postgres_volumes = [
    {
      host_path      = "${var.volume_path}/postgres/data"
      container_path = "/var/lib/postgresql/data"
      read_only      = false
    }
  ]

  # Environment variables for postgres
  postgres_env_vars = {
    POSTGRES_USER     = local.postgres_user
    POSTGRES_PASSWORD = local.postgres_password
    POSTGRES_DB       = local.postgres_db
    POSTGRES_INITDB_ARGS      = "--data-checksums"
    POSTGRES_HOST_AUTH_METHOD = "trust"
  }

  # Environment variables for NocoDB
  nocodb_env_vars = {
    NC_DB = "pg://${local.postgres_name}:5432?u=${local.postgres_user}&p=${local.postgres_password}&d=${local.postgres_db}"
  }

  # Healthcheck configuration for Postgres
  postgres_healthcheck = {
    test         = ["CMD", "pg_isready", "-U", local.postgres_user, "-d", local.postgres_db]
    interval     = "10s"
    timeout      = "2s"
    retries      = 10
    start_period = "5s"
  }
}

module "nocodb_network" {
  source = "../../01-networking/docker-network"
  name   = "nocodb-network"
  subnet = "11.101.0.0/16"
  driver = "bridge"
}

# Create the PostgreSQL container
module "postgres" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.postgres_name
  image          = local.postgres_image
  tag            = local.postgres_tag
  volumes        = local.postgres_volumes
  env_vars       = local.postgres_env_vars
  networks       = [module.nocodb_network.name]
  monitoring     = local.monitoring
  healthcheck    = local.postgres_healthcheck
}

# Create the NocoDB container
module "nocodb" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.container_name
  image          = local.nocodb_image
  tag            = local.nocodb_tag
  volumes        = local.nocodb_volumes
  env_vars       = local.nocodb_env_vars
  networks       = concat([module.nocodb_network.name], var.networks)
  monitoring     = local.monitoring
  depends_on     = [module.postgres]
}

output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = local.nocodb_internal_port
    endpoint     = "http://${local.container_name}:${local.nocodb_internal_port}"
    subdomains   = ["db"]
    publish_via  = "tunnel"
  }
}
