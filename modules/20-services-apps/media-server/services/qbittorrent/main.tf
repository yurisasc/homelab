variable "user_id" {
  description = "User ID for container permissions"
  type        = string
}

variable "group_id" {
  description = "Group ID for container permissions"
  type        = string
}

variable "timezone" {
  description = "Timezone for the container"
  type        = string
}

variable "volume_path" {
  description = "Base directory for volumes"
  type        = string
}

variable "download_root" {
  description = "Directory for downloads"
  type        = string
}

variable "networks" {
  description = "List of networks to which the container should be attached"
  type        = list(string)
}

variable "monitoring" {
  description = "Enable container monitoring"
  type        = bool
  default     = true
}

locals {
  container_name = "qbittorrent"
  image          = "lscr.io/linuxserver/qbittorrent"
  tag            = "libtorrentv1"
  
  qbittorrent_volumes = [
    {
      host_path      = "${var.volume_path}/qbittorrent"
      container_path = "/config"
      read_only      = false
    },
    {
      host_path      = var.download_root
      container_path = "/data/torrents"
      read_only      = false
    }
  ]
  
  qbittorrent_env_vars = {
    PUID        = var.user_id
    PGID        = var.group_id
    TZ          = var.timezone
    WEBUI_PORT  = "8080"
    DOCKER_MODS = "ghcr.io/gabe565/linuxserver-mod-vuetorrent"
  }
  
  qbittorrent_healthcheck = {
    test         = ["CMD", "curl", "--fail", "http://127.0.0.1:8080", "https://google.com"]
    interval     = "30s"
    timeout      = "5s"
    retries      = 10
    start_period = "5s"
  }
}

module "qbittorrent" {
  source         = "../../../../10-services-generic/docker-service"
  container_name = local.container_name
  image          = local.image
  tag            = local.tag
  volumes        = local.qbittorrent_volumes
  env_vars       = local.qbittorrent_env_vars
  healthcheck    = local.qbittorrent_healthcheck
  ports = [{
    internal = 8080
    external = 8080
    protocol = "tcp"
  }]
  networks       = var.networks
  monitoring     = var.monitoring
  restart_policy = "always"
}

output "service_definition" {
  description = "Service definition for qbittorrent"
  value = {
    name         = local.container_name
    primary_port = 8080
    endpoint     = "http://${local.container_name}:8080"
  }
}
