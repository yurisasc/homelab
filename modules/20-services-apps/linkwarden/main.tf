terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

variable "image_tag" {
  description = "The tag for the Linkwarden container image"
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
}

variable "backup_networks" {
  description = "List of networks for backup access to database"
  type        = list(string)
  default     = []
}

locals {
  container_name       = "linkwarden"
  postgres_name        = "linkwarden-postgres"
  meilisearch_name     = "meilisearch"
  linkwarden_image     = "ghcr.io/linkwarden/linkwarden"
  postgres_image       = "postgres"
  postgres_tag         = "16-alpine"
  meilisearch_image    = "getmeili/meilisearch"
  meilisearch_tag      = "v1.12.8"
  linkwarden_image_tag = var.image_tag != "" ? var.image_tag : "latest"
  monitoring           = true
  env_file             = "${path.module}/.env"
  internal_port        = 3000
  postgres_port        = 5432
  postgres_networks = distinct(concat(var.networks, var.backup_networks))

  linkwarden_volumes = [
    {
      host_path      = "${var.volume_path}/data"
      container_path = "/data/data"
      read_only      = false
    }
  ]

  postgres_volumes = [
    {
      host_path      = "${var.volume_path}/pgdata"
      container_path = "/var/lib/postgresql/data"
      read_only      = false
    }
  ]

  meilisearch_volumes = [
    {
      host_path      = "${var.volume_path}/meili_data"
      container_path = "/meili_data"
      read_only      = false
    }
  ]

  linkwarden_env_vars = {
    NEXTAUTH_SECRET = provider::dotenv::get_by_key("NEXTAUTH_SECRET", local.env_file)
    NEXTAUTH_URL    = provider::dotenv::get_by_key("NEXTAUTH_URL", local.env_file)
    DATABASE_URL    = "postgresql://postgres:${provider::dotenv::get_by_key("POSTGRES_PASSWORD", local.env_file)}@${local.postgres_name}:${local.postgres_port}/postgres"
    MEILI_HOST      = "http://${local.meilisearch_name}:7700"
    MEILI_MASTER_KEY = try(provider::dotenv::get_by_key("MEILI_MASTER_KEY", local.env_file), "")
  }

  postgres_env_vars = {
    POSTGRES_PASSWORD = provider::dotenv::get_by_key("POSTGRES_PASSWORD", local.env_file)
  }

  meilisearch_env_vars = {
    MEILI_MASTER_KEY = try(provider::dotenv::get_by_key("MEILI_MASTER_KEY", local.env_file), "")
  }
}

module "postgres" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.postgres_name
  image          = local.postgres_image
  tag            = local.postgres_tag
  volumes        = local.postgres_volumes
  env_vars       = local.postgres_env_vars
  networks       = local.postgres_networks
}

module "meilisearch" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.meilisearch_name
  image          = local.meilisearch_image
  tag            = local.meilisearch_tag
  volumes        = local.meilisearch_volumes
  env_vars       = local.meilisearch_env_vars
  networks       = var.networks
}

module "linkwarden" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.container_name
  image          = local.linkwarden_image
  tag            = local.linkwarden_image_tag
  volumes        = local.linkwarden_volumes
  env_vars       = local.linkwarden_env_vars
  networks       = var.networks
  monitoring     = local.monitoring
  depends_on     = [module.postgres, module.meilisearch]
}

output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = local.internal_port
    endpoint     = "http://${local.container_name}:${local.internal_port}"
    subdomains   = ["links"]
    publish_via  = "tunnel"
  }
}

output "db_backup_config" {
  description = "Database backup configuration for Linkwarden"
  value = {
    name         = "linkwarden"
    type         = "postgres"
    host         = local.postgres_name
    port         = local.postgres_port
    database     = "postgres"
    username     = "postgres"
    password_env = "POSTGRES_PASSWORD"  # Env var name in Linkwarden .env
    env_file     = local.env_file        # Path to Linkwarden .env file
  }
}
