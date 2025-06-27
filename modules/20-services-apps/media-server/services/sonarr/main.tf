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
  container_name = "sonarr"
  image          = "lscr.io/linuxserver/sonarr"
  tag            = "latest"
  
  sonarr_volumes = [
    {
      host_path      = "${var.volume_path}/sonarr"
      container_path = "/config"
      read_only      = false
    },
    {
      host_path      = var.data_root
      container_path = "/data"
      read_only      = false
    }
  ]
  
  sonarr_env_vars = {
    PUID = var.user_id
    PGID = var.group_id
    TZ   = var.timezone
  }
  
  sonarr_healthcheck = {
    test         = ["CMD", "curl", "--fail", "http://127.0.0.1:8989/sonarr/ping"]
    interval     = "30s"
    timeout      = "5s"
    retries      = 10
    start_period = "5s"
  }
}

module "sonarr" {
  source         = "../../../../10-services-generic/docker-service"
  container_name = local.container_name
  image          = local.image
  tag            = local.tag
  volumes        = local.sonarr_volumes
  env_vars       = local.sonarr_env_vars
  healthcheck    = local.sonarr_healthcheck
  ports = [{
    internal = 8989
    external = 8989
    protocol = "tcp"
  }]
  networks       = var.networks
  monitoring     = var.monitoring
  restart_policy = "always"
}

output "service_definition" {
  description = "Service definition for sonarr"
  value = {
    name         = local.container_name
    primary_port = 8989
    endpoint     = "http://${local.container_name}:8989"
  }
}
