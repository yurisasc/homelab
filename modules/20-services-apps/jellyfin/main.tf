terraform {
  required_providers {
    dotenv = { source = "germanbrew/dotenv" }
  }
}

variable "volume_path" {
  description = "Base directory for Jellyfin config"
  type        = string
}
variable "data_path" {
  description = "Base directory for media data mounted at /data"
  type        = string
}
variable "networks" {
  description = "List of networks to attach"
  type        = list(string)
  default     = []
}

locals {
  env_file       = "${path.module}/.env"
  monitoring     = true
  container_name = "jellyfin"
  image          = "lscr.io/linuxserver/jellyfin"
  tag            = "latest"
  internal_port  = 8096

  # UDP ports for DLNA/auto-discovery
  udp_ports = [
    { internal = 7359, external = 7359, protocol = "udp" },
    { internal = 1900, external = 1900, protocol = "udp" }
  ]

  volumes = [
    {
      host_path      = var.volume_path,
      container_path = "/config",
      read_only      = false
    },
    {
      host_path      = var.volume_path,
      container_path = "/cache",
      read_only      = false
    },
    {
      host_path      = var.data_path,
      container_path = "/data",
      read_only      = false
    }
  ]

  env_vars = {
    # If you want to publish external URL, uncomment the following and set HOSTNAME in .env
    JELLYFIN_PublishedServerUrl = "${provider::dotenv::get_by_key("HOSTNAME", local.env_file)}/jellyfin"
    DOCKER_MODS = "linuxserver/mods:jellyfin-opencl-intel"
  }

  # Intel VAAPI/QSV: map the entire /dev/dri directory (per linuxserver/jellyfin docs)
  devices = [
    {
      host_path      = "/dev/dri/renderD128",
      container_path = "/dev/dri/renderD128",
      permissions    = "rwm"
    },
    {
      host_path      = "/dev/dri/card0",
      container_path = "/dev/dri/card0",
      permissions    = "rwm"
    }
  ]
}

module "jellyfin" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.container_name
  image          = local.image
  tag            = local.tag
  volumes        = local.volumes
  env_vars       = local.env_vars
  networks       = var.networks
  monitoring     = local.monitoring
  ports          = local.udp_ports
  devices        = local.devices
}

output "service_definition" {
  description = "Service definition for Jellyfin (reverse proxy)"
  value = {
    name         = local.container_name
    primary_port = local.internal_port
    endpoint     = "http://${local.container_name}:${local.internal_port}"
    subdomains   = ["stream"]
    publish_via  = "reverse_proxy"
    proxied      = false
  }
}
