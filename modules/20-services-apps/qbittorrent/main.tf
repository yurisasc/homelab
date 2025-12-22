variable "volume_path" {
  description = "Base directory for qBittorrent config"
  type        = string
}
 
variable "image_tag" {
  description = "Tag of the qBittorrent image to use"
  type        = string
  default     = ""
}
variable "downloads_path" {
  description = "Directory for downloads mounted at /data/torrents"
  type        = string
}
variable "networks" {
  description = "List of networks to attach"
  type        = list(string)
  default     = []
}

// When true, run qBittorrent through Gluetun by sharing its network namespace
variable "connect_via_gluetun" {
  description = "Route qBittorrent through Gluetun (network_mode=container:gluetun)"
  type        = bool
  default     = false
}

variable "gluetun_container_name" {
  description = "Container name of the Gluetun instance to share network with"
  type        = string
  default     = "gluetun"
}

locals {
  container_name = "qbittorrent"
  image          = "lscr.io/linuxserver/qbittorrent"
  image_tag      = var.image_tag != "" ? var.image_tag : "libtorrentv1"
  monitoring     = true
  internal_port  = 8080

  use_gluetun    = var.connect_via_gluetun
  gluetun_name   = var.gluetun_container_name
  network_mode   = local.use_gluetun ? "container:${local.gluetun_name}" : "bridge"

  env_vars = {
    WEBUI_PORT  = "8080"
    DOCKER_MODS = "ghcr.io/gabe565/linuxserver-mod-vuetorrent"
  }

  volumes = [
    {
      host_path      = var.volume_path,
      container_path = "/config",
      read_only      = false
    },
    {
      host_path      = var.downloads_path,
      container_path = "/data/torrents",
      read_only      = false
    }
  ]

  healthcheck = {
    test     = ["CMD", "curl", "--fail", "http://127.0.0.1:8080", "https://google.com"]
    interval = "60s"
    timeout  = "5s"
    retries  = 10
  }
}

module "qbittorrent" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.container_name
  image          = local.image
  tag            = local.image_tag
  env_vars       = local.env_vars
  volumes        = local.volumes
  network_mode   = local.network_mode
  networks       = local.use_gluetun ? [] : var.networks
  monitoring     = local.monitoring
  healthcheck    = local.healthcheck
  ports          = local.use_gluetun ? [] : [{ internal = local.internal_port, external = local.internal_port, protocol = "tcp" }]
}

output "service_definition" {
  description = "Service definition for qBittorrent (not published)"
  value = {
    name         = local.container_name
    primary_port = local.internal_port
    endpoint     = "http://${local.container_name}:${local.internal_port}"
  }
}
