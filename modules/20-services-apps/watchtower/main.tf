terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

variable "image_tag" {
  description = "The tag for the Watchtower container image"
  type        = string
  default     = "latest"
}

locals {
  container_name = "watchtower"
  image          = "containrrr/watchtower"
  image_tag      = var.image_tag != "" ? var.image_tag : "latest"
  env_file       = "${path.module}/.env"

  env_vars = {
    WATCHTOWER_CLEANUP          = provider::dotenv::get_by_key("WATCHTOWER_CLEANUP", local.env_file)
    WATCHTOWER_POLL_INTERVAL    = provider::dotenv::get_by_key("WATCHTOWER_POLL_INTERVAL", local.env_file)
    WATCHTOWER_INCLUDE_STOPPED  = false
    WATCHTOWER_REVIVE_STOPPED   = false
    WATCHTOWER_ROLLING_RESTART  = true
    WATCHTOWER_NOTIFICATION_URL = provider::dotenv::get_by_key("WATCHTOWER_NOTIFICATION_URL", local.env_file)
    WATCHTOWER_NOTIFICATIONS    = provider::dotenv::get_by_key("WATCHTOWER_NOTIFICATIONS", local.env_file)
  }

  volumes = [
    {
      host_path      = "/var/run/docker.sock"
      container_path = "/var/run/docker.sock"
      read_only      = true
    }
  ]
}

module "watchtower" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.container_name
  image          = local.image
  tag            = local.image_tag
  env_vars       = local.env_vars
  volumes        = local.volumes
}

