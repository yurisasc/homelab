variable "timezone" {
  description = "Timezone for the container"
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

variable "log_level" {
  description = "Log level for flaresolverr"
  type        = string
  default     = "info"
}

variable "log_html" {
  description = "Whether to log HTML"
  type        = string
  default     = "false"
}

variable "captcha_solver" {
  description = "Type of CAPTCHA solver to use"
  type        = string
  default     = "none"
}

locals {
  container_name = "flaresolverr"
  image          = "ghcr.io/flaresolverr/flaresolverr"
  tag            = "latest"
  
  flaresolverr_env_vars = {
    LOG_LEVEL      = var.log_level
    LOG_HTML       = var.log_html
    CAPTCHA_SOLVER = var.captcha_solver
    TZ             = var.timezone
  }
}

module "flaresolverr" {
  source         = "../../../../10-services-generic/docker-service"
  container_name = local.container_name
  image          = local.image
  tag            = local.tag
  env_vars       = local.flaresolverr_env_vars
  ports = [{
    internal = 8191
    external = 8191
    protocol = "tcp"
  }]
  networks       = var.networks
  monitoring     = var.monitoring
  restart_policy = "always"
}

output "service_definition" {
  description = "Service definition for flaresolverr"
  value = {
    name         = local.container_name
    primary_port = 8191
    endpoint     = "http://${local.container_name}:8191"
  }
}
