terraform {
  required_providers {
    dotenv = { source = "germanbrew/dotenv" }
  }
}

variable "volume_path" {
  description = "Base directory for Gluetun state/config mounted at /gluetun"
  type        = string
}

variable "networks" {
  description = "Networks to attach Gluetun to"
  type        = list(string)
  default     = []
}

variable "ports" {
  description = "Ports to publish on the Gluetun container (used to reach services connected via network_mode: container:gluetun)"
  type = list(object({
    internal = number
    external = number
    protocol = string
  }))
  // Default to no published ports. Publish only if you need host access.
  default = []
}

variable "image_tag" {
  description = "Gluetun image tag"
  type        = string
  default     = "v3.40.0"
}

locals {
  env_file       = "${path.module}/.env"
  container_name = "gluetun"
  image          = "qmcgaw/gluetun"
  tag            = var.image_tag

  // Gluetun environment
  env_vars = {
    VPN_SERVICE_PROVIDER     = try(provider::dotenv::get_by_key("VPN_SERVICE_PROVIDER", local.env_file), "mullvad")
    VPN_TYPE                 = try(provider::dotenv::get_by_key("VPN_TYPE", local.env_file), "wireguard")
    WIREGUARD_PRIVATE_KEY    = try(provider::dotenv::get_by_key("WIREGUARD_PRIVATE_KEY", local.env_file), "")
    WIREGUARD_ADDRESSES      = try(provider::dotenv::get_by_key("WIREGUARD_ADDRESSES", local.env_file), "")
    WIREGUARD_PUBLIC_KEY     = try(provider::dotenv::get_by_key("WIREGUARD_PUBLIC_KEY", local.env_file), "")
    WIREGUARD_ENDPOINT_IP    = try(provider::dotenv::get_by_key("WIREGUARD_ENDPOINT_IP", local.env_file), "")
    WIREGUARD_ENDPOINT_PORT  = try(provider::dotenv::get_by_key("WIREGUARD_ENDPOINT_PORT", local.env_file), "")
    SERVER_CITIES            = try(provider::dotenv::get_by_key("SERVER_CITIES", local.env_file), "")
    SERVER_COUNTRIES         = try(provider::dotenv::get_by_key("SERVER_COUNTRIES", local.env_file), "")
    SERVER_HOSTNAMES         = try(
      provider::dotenv::get_by_key("SERVER_HOSTNAMES", local.env_file),
      try(provider::dotenv::get_by_key("SERVER_HOSTNAME", local.env_file), "")
    )
    UPDATER_PERIOD           = try(provider::dotenv::get_by_key("UPDATER_PERIOD", local.env_file), "")
    FIREWALL_OUTBOUND_SUBNETS = try(provider::dotenv::get_by_key("FIREWALL_OUTBOUND_SUBNETS", local.env_file), "")
  }

  volumes = [
    {
      host_path      = var.volume_path,
      container_path = "/gluetun",
      read_only      = false
    }
  ]
}

module "gluetun" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.container_name
  image          = local.image
  tag            = local.tag
  env_vars       = local.env_vars
  volumes        = local.volumes
  networks       = var.networks
  ports          = var.ports

  // Grant minimal privileges required by Gluetun
  capabilities_add = ["NET_ADMIN"]
  devices = [
    {
      host_path      = "/dev/net/tun"
      container_path = "/dev/net/tun"
      permissions    = "rwm"
    }
  ]
}
