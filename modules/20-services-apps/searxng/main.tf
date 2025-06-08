terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

variable "image_tag" {
  description = "The tag for the searxng container image"
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
  container_name = "searxng"
  image          = "searxng/searxng"
  tag            = var.image_tag != "" ? var.image_tag : "latest"
  monitoring     = true
  internal_port  = 8080
  volumes = [
    {
      host_path      = "${var.volume_path}/config"
      container_path = "/etc/searxng"
      read_only      = false
    }
  ]
}

module "searxng" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.container_name
  image          = local.image
  tag            = local.tag
  volumes        = local.volumes
  networks       = var.networks
  monitoring     = local.monitoring
}

output "service_definition" {
  description = "Service definition with ingress configuration"
  value = {
    name         = local.container_name
    primary_port = local.internal_port
    endpoint     = "http://${local.container_name}:${local.internal_port}"
    subdomains   = ["search"]
  }
}
