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
  container_name = "jellyseerr"
  image          = "fallenbagel/jellyseerr"
  tag            = "latest"
  
  jellyseerr_volumes = [
    {
      host_path      = "${var.volume_path}/jellyseerr"
      container_path = "/app/config"
      read_only      = false
    }
  ]
  
  jellyseerr_env_vars = {
    LOG_LEVEL = "debug"
    TZ        = var.timezone
  }
  
  jellyseerr_healthcheck = {
    test         = ["CMD", "wget", "http://127.0.0.1:5055/api/v1/status", "-qO", "/dev/null"]
    interval     = "30s"
    timeout      = "5s"
    retries      = 10
    start_period = "5s"
  }
}

module "jellyseerr" {
  source         = "../../../../10-services-generic/docker-service"
  container_name = local.container_name
  image          = local.image
  tag            = local.tag
  volumes        = local.jellyseerr_volumes
  env_vars       = local.jellyseerr_env_vars
  healthcheck    = local.jellyseerr_healthcheck
  ports = [{
    internal = 5055
    external = 5055
    protocol = "tcp"
  }]
  networks       = var.networks
  monitoring     = var.monitoring
  restart_policy = "always"
}

output "service_definition" {
  description = "Service definition for integration with networking modules"
  value = {
    name         = local.container_name
    primary_port = 5055
    endpoint     = "http://${local.container_name}:5055"
    subdomains   = ["requests"]
    publish_via  = "reverse_proxy"
    proxied      = false
  }
}
