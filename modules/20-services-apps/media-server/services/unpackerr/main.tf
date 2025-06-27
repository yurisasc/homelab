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

variable "download_root" {
  description = "Directory for downloads"
  type        = string
}

variable "sonarr_api_key" {
  description = "API key for Sonarr"
  type        = string
  sensitive   = true
}

variable "radarr_api_key" {
  description = "API key for Radarr"
  type        = string
  sensitive   = true
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
  container_name = "unpackerr"
  image          = "golift/unpackerr"
  tag            = "latest"
  
  unpackerr_volumes = [
    {
      host_path      = var.download_root
      container_path = "/data/torrents"
      read_only      = false
    }
  ]
  
  unpackerr_env_vars = {
    TZ                     = var.timezone
    UN_SONARR_0_URL        = "http://sonarr:8989/sonarr"
    UN_SONARR_0_API_KEY    = var.sonarr_api_key
    UN_RADARR_0_URL        = "http://radarr:7878/radarr"
    UN_RADARR_0_API_KEY    = var.radarr_api_key
  }
  
  unpackerr_security_opts = [
    "no-new-privileges:true"
  ]
}

module "unpackerr" {
  source         = "../../../../10-services-generic/docker-service"
  container_name = local.container_name
  image          = local.image
  tag            = local.tag
  volumes        = local.unpackerr_volumes
  env_vars       = local.unpackerr_env_vars
  security_opts  = local.unpackerr_security_opts
  networks       = var.networks
  monitoring     = var.monitoring
  restart_policy = "always"
  user           = "${var.user_id}:${var.group_id}"
}

output "service_definition" {
  description = "Service definition for unpackerr"
  value = {
    name         = local.container_name
    endpoint     = "http://${local.container_name}"
  }
}
