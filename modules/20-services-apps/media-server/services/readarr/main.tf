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
  container_name = "readarr"
  image          = "lscr.io/linuxserver/readarr"
  tag            = "develop"
  
  readarr_volumes = [
    {
      host_path      = "${var.volume_path}/readarr"
      container_path = "/config"
      read_only      = false
    },
    {
      host_path      = var.data_root
      container_path = "/books"
      read_only      = false
    }
  ]
  
  readarr_env_vars = {
    PUID = var.user_id
    PGID = var.group_id
    TZ   = var.timezone
  }
}

module "readarr" {
  source         = "../../../../10-services-generic/docker-service"
  container_name = local.container_name
  image          = local.image
  tag            = local.tag
  volumes        = local.readarr_volumes
  env_vars       = local.readarr_env_vars
  ports = [{
    internal = 8787
    external = 8787
    protocol = "tcp"
  }]
  networks       = var.networks
  monitoring     = var.monitoring
  restart_policy = "always"
}

output "service_definition" {
  description = "Service definition for readarr"
  value = {
    name         = local.container_name
    primary_port = 8787
    endpoint     = "http://${local.container_name}:8787"
  }
}
