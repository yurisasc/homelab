terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

variable "image_tag" {
  description = "The tag for the Calibre Web container image"
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

variable "user_id" {
  description = "User ID for container permissions"
  type        = string
  default     = "1000"
}

variable "group_id" {
  description = "Group ID for container permissions"
  type        = string
  default     = "1000"
}

variable "timezone" {
  description = "Timezone for the container"
  type        = string
  default     = "UTC"
}

locals {
  container_name        = "calibre-web-automated"
  calibre_image         = "crocodilestick/calibre-web-automated"
  calibre_tag           = var.image_tag
  env_file              = "${path.module}/.env"
  calibre_internal_port = 8083
  docker_mods           = "lscr.io/linuxserver/mods:universal-calibre-v7.16.0"

  # Define volumes
  calibre_volumes = [
    {
      host_path      = "${var.volume_path}/config"
      container_path = "/config"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/ingest"
      container_path = "/cwa-book-ingest"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/library"
      container_path = "/calibre-library"
      read_only      = false
    }
  ]

  # Environment variables for Calibre Web
  calibre_env_vars = {
    PUID        = var.user_id
    PGID        = var.group_id
    TZ          = var.timezone
    DOCKER_MODS = local.docker_mods
  }
}

# Create the Calibre Web container
module "calibre" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.container_name
  image          = local.calibre_image
  tag            = local.calibre_tag
  volumes        = local.calibre_volumes
  env_vars       = local.calibre_env_vars
  networks       = concat(var.networks)
  restart_policy = "always"
}

output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = local.calibre_internal_port
    endpoint     = "http://${local.container_name}:${local.calibre_internal_port}"
    subdomains   = ["calibre"]
    publish_via  = "reverse_proxy"
    proxied      = true
  }
}
