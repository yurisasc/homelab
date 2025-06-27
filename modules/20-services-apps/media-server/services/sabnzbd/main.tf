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
  container_name = "sabnzbd"
  image          = "lscr.io/linuxserver/sabnzbd"
  tag            = "latest"
  
  sabnzbd_volumes = [
    {
      host_path      = "${var.volume_path}/sabnzbd/config"
      container_path = "/config"
      read_only      = false
    },
    {
      host_path      = "${var.data_root}/usenet/downloads"
      container_path = "/downloads"
      read_only      = false
    }
  ]
  
  sabnzbd_env_vars = {
    PUID = var.user_id
    PGID = var.group_id
    TZ   = var.timezone
  }
}

module "sabnzbd" {
  source         = "../../../../10-services-generic/docker-service"
  container_name = local.container_name
  image          = local.image
  tag            = local.tag
  volumes        = local.sabnzbd_volumes
  env_vars       = local.sabnzbd_env_vars
  ports = [{
    internal = 8080
    external = 6789
    protocol = "tcp"
  }]
  networks       = var.networks
  monitoring     = var.monitoring
  restart_policy = "unless-stopped"
}

output "service_definition" {
  description = "Service definition for integration with networking modules"
  value = {
    name         = local.container_name
    primary_port = 8080
    endpoint     = "http://${local.container_name}:8080"
    subdomains   = ["sabnzbd"]
    publish_via  = "reverse_proxy"
    proxied      = false
  }
}
