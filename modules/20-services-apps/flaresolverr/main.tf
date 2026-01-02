terraform {
  required_providers {
    dotenv = { source = "germanbrew/dotenv" }
  }
}

variable "networks" {
  description = "Networks to attach to Flaresolverr"
  type        = list(string)
}

variable "image_tag" {
  description = "The tag for the Flaresolverr container image"
  type        = string
  default     = "nodriver"
}

locals {
  container_name = "flaresolverr"
  image          = "21hsmw/flaresolverr"
  port           = 8191
  env_file       = "${path.module}/.env"
  monitoring     = true

  env_vars = {
    LOG_LEVEL      = try(provider::dotenv::get_by_key("LOG_LEVEL", local.env_file), "")
    LOG_HTML       = try(provider::dotenv::get_by_key("LOG_HTML", local.env_file), "")
    CAPTCHA_SOLVER = try(provider::dotenv::get_by_key("CAPTCHA_SOLVER", local.env_file), "")
  }
}

module "flaresolverr" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.container_name
  image          = local.image
  tag            = var.image_tag
  env_vars       = local.env_vars
  networks       = var.networks
  monitoring     = local.monitoring
  ports          = [{ internal = local.port, external = local.port, protocol = "tcp" }]
}

output "endpoint" {
  description = "The endpoint for Flaresolverr"
  value       = "http://${local.container_name}:${local.port}"
}

output "container_name" {
  description = "The name of the Flaresolverr container"
  value       = local.container_name
}
