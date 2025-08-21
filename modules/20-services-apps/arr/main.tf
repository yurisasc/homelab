terraform {
  required_providers {
    dotenv = { source = "germanbrew/dotenv" }
  }
}

variable "volume_path" {
  description = "Base directory for config volumes for *arr stack"
  type        = string
}
variable "data_path" {
  description = "Base directory for media/data mounted at /data"
  type        = string
}
variable "downloads_path" {
  description = "Directory for downloads mounted at /data/torrents"
  type        = string
}
variable "networks" {
  description = "Networks to attach all containers to"
  type        = list(string)
  default     = []
}
variable "proxy_networks" {
  description = "Extra networks to attach only to published services (e.g., Jellyseerr)"
  type        = list(string)
  default     = []
}

variable "qbittorrent_host" {
  description = "Hostname to reach qBittorrent (use 'qbittorrent' normally, 'gluetun' when qBittorrent shares Gluetun network)"
  type        = string
  default     = "qbittorrent"
}

locals {
  env_file   = "${path.module}/.env"
  monitoring = true

  sonarr_name       = "sonarr"
  radarr_name       = "radarr"
  lidarr_name       = "lidarr"
  bazarr_name       = "bazarr"
  prowlarr_name     = "prowlarr"
  jellyseerr_name   = "jellyseerr"
  flaresolverr_name = "flaresolverr"
  unpackerr_name    = "unpackerr"
  cleanuparr_name   = "cleanuparr"
  decluttarr_name   = "decluttarr"

  sonarr_image       = "lscr.io/linuxserver/sonarr"
  radarr_image       = "lscr.io/linuxserver/radarr"
  lidarr_image       = "lscr.io/linuxserver/lidarr"
  bazarr_image       = "lscr.io/linuxserver/bazarr"
  prowlarr_image     = "lscr.io/linuxserver/prowlarr"
  jellyseerr_image   = "ghcr.io/fallenbagel/jellyseerr"
  flaresolverr_image = "21hsmw/flaresolverr"
  unpackerr_image    = "ghcr.io/unpackerr/unpackerr"
  cleanuparr_image   = "ghcr.io/cleanuparr/cleanuparr"
  decluttarr_image   = "ghcr.io/manimatter/decluttarr"

  sonarr_port       = 8989
  radarr_port       = 7878
  lidarr_port       = 8686
  bazarr_port       = 6767
  prowlarr_port     = 9696
  jellyseerr_port   = 5055
  flaresolverr_port = 8191

  lidarr_healthcheck     = { test = ["CMD", "curl", "--fail", "http://127.0.0.1:${local.lidarr_port}/lidarr/ping"], interval = "60s", timeout = "5s", retries = 10 }
  bazarr_healthcheck     = { test = ["CMD", "curl", "--fail", "http://127.0.0.1:${local.bazarr_port}/bazarr/ping"], interval = "60s", timeout = "5s", retries = 10 }
  jellyseerr_healthcheck = { test = ["CMD", "wget", "http://127.0.0.1:${local.jellyseerr_port}/api/v1/status", "-qO", "/dev/null"], interval = "60s", timeout = "5s", retries = 10 }

  jellyseerr_env = { LOG_LEVEL = "debug" }
  flaresolverr_env = {
    LOG_LEVEL      = try(provider::dotenv::get_by_key("LOG_LEVEL", local.env_file), "")
    LOG_HTML       = try(provider::dotenv::get_by_key("LOG_HTML", local.env_file), "")
    CAPTCHA_SOLVER = try(provider::dotenv::get_by_key("CAPTCHA_SOLVER", local.env_file), "")
  }
  unpackerr_env = {
    UN_SONARR_0_URL     = "http://${local.sonarr_name}:${local.sonarr_port}/sonarr"
    UN_SONARR_0_API_KEY = provider::dotenv::get_by_key("SONARR_API_KEY", local.env_file)
    UN_RADARR_0_URL     = "http://${local.radarr_name}:${local.radarr_port}/radarr"
    UN_RADARR_0_API_KEY = provider::dotenv::get_by_key("RADARR_API_KEY", local.env_file)
  }
  cleanuparr_env = {
    QUEUECLEANER__ENABLED                           = true
    QUEUECLEANER__IMPORT_FAILED_MAX_STRIKES         = 3
    QUEUECLEANER__STALLED_MAX_STRIKES               = 3
    QUEUECLEANER__DOWNLOADING_METADATA_MAX_STRIKES  = 3
    QUEUECLEANER__STALLED_RESET_STRIKES_ON_PROGRESS = true
    TRIGGERS__QUEUECLEANER                          = "0 0 0/1 * * ?"
    CONTENTBLOCKER__ENABLED                         = true
    CONTENTBLOCKER__IGNORED_DOWNLOADS_PATH          = "/usr/ignored.txt"
    TRIGGERS__CONTENTBLOCKER                        = "0 0 0/1 * * ?"
    DOWNLOAD_CLIENT                                 = "qBittorrent"
    QBITTORRENT__URL                                = "http://${var.qbittorrent_host}:8080"
    QBITTORRENT__PASSWORD                           = provider::dotenv::get_by_key("QBITTORRENT_PASSWORD", local.env_file)
    SONARR__ENABLED                                 = true
    SONARR__BLOCK__PATH                             = "/usr/blacklist.json"
    SONARR__INSTANCES__0__URL                       = "http://${local.sonarr_name}:${local.sonarr_port}/sonarr"
    SONARR__INSTANCES__0__APIKEY                    = provider::dotenv::get_by_key("SONARR_API_KEY", local.env_file)
    RADARR__ENABLED                                 = true
    RADARR__BLOCK__PATH                             = "/usr/blacklist.json"
    RADARR__INSTANCES__0__URL                       = "http://${local.radarr_name}:${local.radarr_port}/radarr"
    RADARR__INSTANCES__0__APIKEY                    = provider::dotenv::get_by_key("RADARR_API_KEY", local.env_file)
  }

  decluttarr_env = {
    RADARR_URL                     = "http://${local.radarr_name}:${local.radarr_port}/radarr"
    RADARR_KEY                     = provider::dotenv::get_by_key("RADARR_API_KEY", local.env_file)
    SONARR_URL                     = "http://${local.sonarr_name}:${local.sonarr_port}/sonarr"
    SONARR_KEY                     = provider::dotenv::get_by_key("SONARR_API_KEY", local.env_file)
    LIDARR_URL                     = "http://${local.lidarr_name}:${local.lidarr_port}/lidarr"
    LIDARR_KEY                     = provider::dotenv::get_by_key("LIDARR_API_KEY", local.env_file)
    QBITTORRENT_URL                = "http://${var.qbittorrent_host}:8080"
    QBITTORRENT_USERNAME           = provider::dotenv::get_by_key("QBITTORRENT_USERNAME", local.env_file)
    QBITTORRENT_PASSWORD           = provider::dotenv::get_by_key("QBITTORRENT_PASSWORD", local.env_file)
    LOG_LEVEL                      = try(provider::dotenv::get_by_key("DECLUTTARR_LOG_LEVEL", local.env_file), "")
    TEST_RUN                       = try(provider::dotenv::get_by_key("DECLUTTARR_TEST_RUN", local.env_file), "")
    REMOVE_TIMER                   = try(provider::dotenv::get_by_key("DECLUTTARR_REMOVE_TIMER", local.env_file), "")
    REMOVE_FAILED                  = try(provider::dotenv::get_by_key("DECLUTTARR_REMOVE_FAILED", local.env_file), "")
    REMOVE_FAILED_IMPORTS          = try(provider::dotenv::get_by_key("DECLUTTARR_REMOVE_FAILED_IMPORTS", local.env_file), "")
    REMOVE_METADATA_MISSING        = try(provider::dotenv::get_by_key("DECLUTTARR_REMOVE_METADATA_MISSING", local.env_file), "")
    REMOVE_MISSING_FILES           = try(provider::dotenv::get_by_key("DECLUTTARR_REMOVE_MISSING_FILES", local.env_file), "")
    REMOVE_ORPHANS                 = try(provider::dotenv::get_by_key("DECLUTTARR_REMOVE_ORPHANS", local.env_file), "")
    REMOVE_SLOW                    = try(provider::dotenv::get_by_key("DECLUTTARR_REMOVE_SLOW", local.env_file), "")
    REMOVE_STALLED                 = try(provider::dotenv::get_by_key("DECLUTTARR_REMOVE_STALLED", local.env_file), "")
    REMOVE_UNMONITORED             = try(provider::dotenv::get_by_key("DECLUTTARR_REMOVE_UNMONITORED", local.env_file), "")
    RUN_PERIODIC_RESCANS           = try(provider::dotenv::get_by_key("DECLUTTARR_RUN_PERIODIC_RESCANS", local.env_file), "")
    PERMITTED_ATTEMPTS             = try(provider::dotenv::get_by_key("DECLUTTARR_PERMITTED_ATTEMPTS", local.env_file), "")
    NO_STALLED_REMOVAL_QBIT_TAG    = try(provider::dotenv::get_by_key("DECLUTTARR_REMOVAL_QBIT_TAG", local.env_file), "")
    MIN_DOWNLOAD_SPEED             = try(provider::dotenv::get_by_key("DECLUTTARR_MIN_DOWNLOAD_SPEED", local.env_file), "")
    FAILED_IMPORT_MESSAGE_PATTERNS = try(provider::dotenv::get_by_key("DECLUTTARR_FAILED_IMPORT_MESSAGE_PATTERNS", local.env_file), "")
    IGNORED_DOWNLOAD_CLIENTS       = try(provider::dotenv::get_by_key("DECLUTTARR_IGNORED_DOWNLOAD_CLIENTS", local.env_file), "")
  }
}

# Sonarr
module "sonarr" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.sonarr_name
  image          = local.sonarr_image
  volumes = [
    { host_path = "${var.volume_path}/sonarr", container_path = "/config", read_only = false },
    { host_path = var.data_path, container_path = "/data", read_only = false }
  ]
  networks    = var.networks
  monitoring  = local.monitoring
  ports       = [{ internal = local.sonarr_port, external = local.sonarr_port, protocol = "tcp" }]
}

# Radarr
module "radarr" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.radarr_name
  image          = local.radarr_image
  volumes = [
    { host_path = "${var.volume_path}/radarr", container_path = "/config", read_only = false },
    { host_path = var.data_path, container_path = "/data", read_only = false }
  ]
  networks    = var.networks
  monitoring  = local.monitoring
  ports       = [{ internal = local.radarr_port, external = local.radarr_port, protocol = "tcp" }]
}

# Lidarr
module "lidarr" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.lidarr_name
  image          = local.lidarr_image
  volumes = [
    { host_path = "${var.volume_path}/lidarr", container_path = "/config", read_only = false },
    { host_path = var.data_path, container_path = "/data", read_only = false }
  ]
  networks    = var.networks
  monitoring  = local.monitoring
  healthcheck = local.lidarr_healthcheck
  ports       = [{ internal = local.lidarr_port, external = local.lidarr_port, protocol = "tcp" }]
}

# Bazarr
module "bazarr" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.bazarr_name
  image          = local.bazarr_image
  volumes = [
    { host_path = "${var.volume_path}/bazarr/config", container_path = "/config", read_only = false },
    { host_path = var.data_path, container_path = "/data", read_only = false }
  ]
  networks    = var.networks
  monitoring  = local.monitoring
  healthcheck = local.bazarr_healthcheck
  ports       = [{ internal = local.bazarr_port, external = local.bazarr_port, protocol = "tcp" }]
}

# Prowlarr
module "prowlarr" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.prowlarr_name
  image          = local.prowlarr_image
  volumes = [
    { host_path = "${var.volume_path}/prowlarr", container_path = "/config", read_only = false }
  ]
  networks    = var.networks
  monitoring  = local.monitoring
  ports       = [{ internal = local.prowlarr_port, external = local.prowlarr_port, protocol = "tcp" }]
}

# Jellyseerr (published via reverse proxy)
module "jellyseerr" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.jellyseerr_name
  image          = local.jellyseerr_image
  volumes        = [{ host_path = "${var.volume_path}/jellyseerr", container_path = "/app/config", read_only = false }]
  env_vars       = local.jellyseerr_env
  networks       = concat(var.networks, var.proxy_networks)
  monitoring     = local.monitoring
  healthcheck    = local.jellyseerr_healthcheck
  ports          = [{ internal = local.jellyseerr_port, external = local.jellyseerr_port, protocol = "tcp" }]
}

# Flaresolverr
module "flaresolverr" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.flaresolverr_name
  image          = local.flaresolverr_image
  tag            = "nodriver"
  env_vars       = local.flaresolverr_env
  networks       = var.networks
  monitoring     = local.monitoring
  ports          = [{ internal = local.flaresolverr_port, external = local.flaresolverr_port, protocol = "tcp" }]
}

# Unpackerr
module "unpackerr" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.unpackerr_name
  image          = local.unpackerr_image
  env_vars       = local.unpackerr_env
  volumes        = [{ host_path = var.downloads_path, container_path = "/data/torrents", read_only = false }]
  networks       = var.networks
  monitoring     = local.monitoring
}

# Cleanuparr
module "cleanuparr" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.cleanuparr_name
  image          = local.cleanuparr_image
  env_vars       = local.cleanuparr_env
  volumes = [
    { host_path = "${var.volume_path}/cleanuparr/logs", container_path = "/var/logs", read_only = false },
    { host_path = "${var.volume_path}/cleanuparr/ignored.txt", container_path = "/usr/ignored.txt", read_only = false },
    { host_path = "${var.volume_path}/cleanuparr/blacklist.json", container_path = "/usr/blacklist.json", read_only = false }
  ]
  networks   = var.networks
  monitoring = local.monitoring
}

module "decluttarr" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.decluttarr_name
  image          = local.decluttarr_image
  env_vars       = local.decluttarr_env
  networks       = var.networks
  monitoring     = local.monitoring
}

output "service_definition" {
  description = "Service definition for Jellyseerr (reverse proxy)"
  value = {
    name         = local.jellyseerr_name
    primary_port = local.jellyseerr_port
    endpoint     = "http://${local.jellyseerr_name}:${local.jellyseerr_port}"
    subdomains   = ["req"]
    publish_via  = "reverse_proxy"
    proxied      = true
  }
}
