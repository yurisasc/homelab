terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

locals {
  monitoring = true

  # Define common healthcheck settings
  healthcheck_interval = "30s"
  healthcheck_retries  = 10
}

# Create dedicated network for media server components
module "media_server_network" {
  source = "../../01-networking/docker-network"
  name   = "media-server"
  subnet = "11.102.0.0/16"
  driver = "bridge"
}

# Import service modules
module "sonarr" {
  source = "./services/sonarr"

  user_id     = var.user_id
  group_id    = var.group_id
  timezone    = var.timezone
  volume_path = var.volume_path
  data_root   = var.data_root
  networks    = concat([module.media_server_network.name], var.networks)
  monitoring  = local.monitoring
}

module "radarr" {
  source = "./services/radarr"

  user_id     = var.user_id
  group_id    = var.group_id
  timezone    = var.timezone
  volume_path = var.volume_path
  data_root   = var.data_root
  networks    = concat([module.media_server_network.name], var.networks)
  monitoring  = local.monitoring
}

module "readarr" {
  source = "./services/readarr"

  user_id     = var.user_id
  group_id    = var.group_id
  timezone    = var.timezone
  volume_path = var.volume_path
  data_root   = var.data_root
  networks    = concat([module.media_server_network.name], var.networks)
  monitoring  = local.monitoring
}

module "jellyseerr" {
  source = "./services/jellyseerr"

  timezone    = var.timezone
  volume_path = var.volume_path
  networks    = concat([module.media_server_network.name], var.networks)
  monitoring  = local.monitoring
}

module "prowlarr" {
  source = "./services/prowlarr"

  user_id     = var.user_id
  group_id    = var.group_id
  timezone    = var.timezone
  volume_path = var.volume_path
  networks    = concat([module.media_server_network.name], var.networks)
  monitoring  = local.monitoring
}

module "qbittorrent" {
  source = "./services/qbittorrent"

  user_id       = var.user_id
  group_id      = var.group_id
  timezone      = var.timezone
  volume_path   = var.volume_path
  download_root = var.download_root
  networks      = concat([module.media_server_network.name], var.networks)
  monitoring    = local.monitoring
}

module "unpackerr" {
  source = "./services/unpackerr"

  user_id        = var.user_id
  group_id       = var.group_id
  timezone       = var.timezone
  download_root  = var.download_root
  sonarr_api_key = var.sonarr_api_key
  radarr_api_key = var.radarr_api_key
  networks       = concat([module.media_server_network.name], var.networks)
  monitoring     = local.monitoring
}

module "jellyfin" {
  source = "./services/jellyfin"

  user_id     = var.user_id
  group_id    = var.group_id
  timezone    = var.timezone
  volume_path = var.volume_path
  data_root   = var.data_root
  hostname    = var.hostname
  networks    = concat([module.media_server_network.name], var.networks)
  monitoring  = local.monitoring
}

module "sabnzbd" {
  source = "./services/sabnzbd"

  user_id     = var.user_id
  group_id    = var.group_id
  timezone    = var.timezone
  volume_path = var.volume_path
  data_root   = var.data_root
  networks    = concat([module.media_server_network.name], var.networks)
  monitoring  = local.monitoring
}

module "flaresolverr" {
  source = "./services/flaresolverr"

  timezone       = var.timezone
  log_level      = "info"
  log_html       = "false"
  captcha_solver = "none"
  networks       = concat([module.media_server_network.name], var.networks)
  monitoring     = local.monitoring
}

module "autoheal" {
  source = "./services/autoheal"

  networks   = concat([module.media_server_network.name], var.networks)
  monitoring = local.monitoring
}
