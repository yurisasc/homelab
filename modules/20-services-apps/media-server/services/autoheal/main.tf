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
  container_name = "autoheal"
  image          = "willfarrell/autoheal"
  tag            = "latest"
  
  autoheal_env_vars = {
    AUTOHEAL_CONTAINER_LABEL = "all"
  }
  
  autoheal_volumes = [
    {
      host_path      = "/var/run/docker.sock"
      container_path = "/var/run/docker.sock"
      read_only      = false
    }
  ]
}

module "autoheal" {
  source         = "../../../../10-services-generic/docker-service"
  container_name = local.container_name
  image          = local.image
  tag            = local.tag
  volumes        = local.autoheal_volumes
  env_vars       = local.autoheal_env_vars
  networks       = var.networks
  monitoring     = var.monitoring
  restart_policy = "always"
}

output "service_definition" {
  description = "Service definition for autoheal"
  value = {
    name     = local.container_name
    endpoint = "http://${local.container_name}"
  }
}
