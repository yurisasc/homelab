terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

variable "image_tag" {
  description = "The tag for the EmulatorJS container image"
  type        = string
  default     = "latest"
}

variable "volume_path" {
  description = "Base directory for volumes"
  type        = string
}

locals {
  container_name = "emulatorjs"
  image          = "linuxserver/emulatorjs"
  image_tag      = var.image_tag != "" ? var.image_tag : "latest"
  monitoring     = true
  env_file       = "${path.module}/.env"
  frontend_port  = provider::dotenv::get_by_key("EMULATORJS_FRONTEND_PORT", local.env_file)
  config_port    = provider::dotenv::get_by_key("EMULATORJS_CONFIG_PORT", local.env_file)
  backend_port   = provider::dotenv::get_by_key("EMULATORJS_BACKEND_PORT", local.env_file)
  ports = [
    {
      internal = 3000
      external = local.config_port
      protocol = "tcp"
    },
    {
      internal = 80
      external = local.frontend_port
      protocol = "tcp"
    },
    {
      internal = 4001
      external = local.backend_port
      protocol = "tcp"
    }
  ]
  volumes = [
    {
      host_path      = "${var.volume_path}/config"
      container_path = "/config"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/data"
      container_path = "/data"
      read_only      = false
    }
  ]
}

module "emulatorjs" {
  source = "../../10-services-generic/docker-service"

  container_name = local.container_name
  image          = local.image
  tag            = local.image_tag
  volumes        = local.volumes
  ports          = local.ports
  monitoring     = local.monitoring
}

output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = module.emulatorjs.container_name
    primary_port = local.frontend_port
    endpoint     = "http://${module.emulatorjs.container_name}:${local.frontend_port}"
  }
}
