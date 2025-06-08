terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

variable "image_tag" {
  description = "The tag for the Pterodactyl Wings container image"
  type        = string
  default     = "v1.11.3"
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
  container_name = "pterodactyl-wings"
  image          = "ghcr.io/pterodactyl/wings"
  image_tag      = var.image_tag != "" ? var.image_tag : "v1.11.3"
  monitoring     = false
  env_file       = "${path.module}/.env"
  subdomains     = ["wings"]

  # Volumes configuration
  volumes = [
    {
      host_path      = "/var/run/docker.sock"
      container_path = "/var/run/docker.sock"
      read_only      = false
    },
    {
      host_path      = "/var/lib/docker/containers/"
      container_path = "/var/lib/docker/containers/"
      read_only      = false
    },
    {
      host_path      = "/etc/ssl/certs"
      container_path = "/etc/ssl/certs"
      read_only      = true
    },
    {
      host_path      = "${var.volume_path}/etc"
      container_path = "/etc/pterodactyl/"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/var/lib"
      container_path = "/var/lib/pterodactyl/"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/var/log"
      container_path = "/var/log/pterodactyl/"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/tmp"
      container_path = "/tmp/pterodactyl/"
      read_only      = false
    },
  ]

  # Environment variables
  env_vars = {
    TZ             = "Australia/Brisbane"
    WINGS_UID      = 988
    WINGS_GID      = 988
    WINGS_USERNAME = "pterodactyl"
  }
}

# Create a custom Docker network for wings
module "wings_network" {
  source = "../../../01-networking/docker-network"

  name       = "ptero-wings"
  driver     = "bridge"
  attachable = true
  subnet     = "172.32.0.0/16"
  options = {
    "com.docker.network.bridge.name" = "ptero-wings"
  }
}

module "wings" {
  source         = "../../../10-services-generic/docker-service"
  container_name = local.container_name
  image          = local.image
  tag            = local.image_tag
  volumes        = local.volumes
  env_vars       = local.env_vars
  networks       = concat([module.wings_network.name], var.networks)
  monitoring     = local.monitoring
  privileged     = true
}

output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = 443
    endpoint     = "http://${local.container_name}:443"
    subdomains   = local.subdomains
  }
}
