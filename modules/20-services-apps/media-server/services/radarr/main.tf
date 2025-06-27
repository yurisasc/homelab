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

variable "data_root" {
  description = "Root directory for media data"
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
  container_name = "radarr"
  image          = "lscr.io/linuxserver/radarr"
  tag            = "latest"
  
  radarr_volumes = [
    {
      host_path      = "${var.volume_path}/radarr"
      container_path = "/config"
      read_only      = false
    },
    {
      host_path      = var.data_root
      container_path = "/data"
      read_only      = false
    }
  ]
  
  radarr_env_vars = {
    PUID = var.user_id
    PGID = var.group_id
    TZ   = var.timezone
  }
  
  radarr_healthcheck = {
    test         = ["CMD", "curl", "--fail", "http://127.0.0.1:7878/radarr/ping"]
    interval     = "30s"
    timeout      = "5s"
    retries      = 10
    start_period = "5s"
  }
}

module "radarr" {
  source         = "../../../../10-services-generic/docker-service"
  container_name = local.container_name
  image          = local.image
  tag            = local.tag
  volumes        = local.radarr_volumes
  env_vars       = local.radarr_env_vars
  healthcheck    = local.radarr_healthcheck
  ports = [{
    internal = 7878
    external = 7878
    protocol = "tcp"
  }]
  networks       = var.networks
  monitoring     = var.monitoring
  restart_policy = "always"
}

output "service_definition" {
  description = "Service definition for radarr"
  value = {
    name         = local.container_name
    primary_port = 7878
    endpoint     = "http://${local.container_name}:7878"
  }
}
