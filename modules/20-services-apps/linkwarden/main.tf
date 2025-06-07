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

locals {
  container_name       = "linkwarden"
  postgres_name        = "linkwarden-postgres"
  linkwarden_image     = "ghcr.io/linkwarden/linkwarden"
  postgres_image       = "postgres"
  postgres_tag         = "16-alpine"
  linkwarden_image_tag = var.image_tag != "" ? var.image_tag : "latest"
  monitoring           = true
  env_file             = "${path.module}/.env"
  internal_port        = 3000
  postgres_port        = 5432

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

  linkwarden_env_vars = {
    NEXTAUTH_SECRET = provider::dotenv::get_by_key("NEXTAUTH_SECRET", local.env_file)
    NEXTAUTH_URL    = provider::dotenv::get_by_key("NEXTAUTH_URL", local.env_file)
    DATABASE_URL    = "postgresql://postgres:${provider::dotenv::get_by_key("POSTGRES_PASSWORD", local.env_file)}@${local.postgres_name}:${local.postgres_port}/postgres"
  }

  postgres_env_vars = {
    POSTGRES_PASSWORD = provider::dotenv::get_by_key("POSTGRES_PASSWORD", local.env_file)
  }
}

module "postgres" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.postgres_name
  image          = local.postgres_image
  tag            = local.postgres_tag
  volumes        = local.postgres_volumes
  env_vars       = local.postgres_env_vars
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
  depends_on     = [module.postgres]
}

output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = local.internal_port
    endpoint     = "http://${local.container_name}:${local.internal_port}"
    subdomains   = ["links"]
  }
}
