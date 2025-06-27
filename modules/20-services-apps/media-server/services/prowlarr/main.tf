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
  container_name = "prowlarr"
  image          = "lscr.io/linuxserver/prowlarr"
  tag            = "latest"
  
  prowlarr_volumes = [
    {
      host_path      = "${var.volume_path}/prowlarr"
      container_path = "/config"
      read_only      = false
    }
  ]
  
  prowlarr_env_vars = {
    PUID = var.user_id
    PGID = var.group_id
    TZ   = var.timezone
  }
  
  prowlarr_healthcheck = {
    test         = ["CMD", "curl", "--fail", "http://127.0.0.1:9696/prowlarr/ping"]
    interval     = "30s"
    timeout      = "5s"
    retries      = 10
    start_period = "5s"
  }
}

module "prowlarr" {
  source         = "../../../../10-services-generic/docker-service"
  container_name = local.container_name
  image          = local.image
  tag            = local.tag
  volumes        = local.prowlarr_volumes
  env_vars       = local.prowlarr_env_vars
  healthcheck    = local.prowlarr_healthcheck
  ports = [{
    internal = 9696
    external = 9696
    protocol = "tcp"
  }]
  networks       = var.networks
  monitoring     = var.monitoring
  restart_policy = "always"
}

output "service_definition" {
  description = "Service definition for prowlarr"
  value = {
    name         = local.container_name
    primary_port = 9696
    endpoint     = "http://${local.container_name}:9696"
  }
}
