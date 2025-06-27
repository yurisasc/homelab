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

variable "hostname" {
  description = "Hostname for the Jellyfin PublishedServerUrl"
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
  container_name = "jellyfin"
  image          = "jellyfin/jellyfin"
  tag            = "latest"
  
  internal_ports = [
    {
      internal = 8096
      external = 8096
      protocol = "tcp"
    },
    {
      internal = 7359
      external = 7359
      protocol = "udp"
    },
    {
      internal = 1900
      external = 1900
      protocol = "udp"
    }
  ]
  
  jellyfin_volumes = [
    {
      host_path      = "${var.volume_path}/jellyfin"
      container_path = "/config"
      read_only      = false
    },
    {
      host_path      = "${var.data_root}"
      container_path = "/data"
      read_only      = false
    }
  ]
  
  jellyfin_devices = [
    "/dev/dri/:/dev/dri/"
  ]
  
  jellyfin_env_vars = {
    PUID                       = var.user_id
    PGID                       = var.group_id
    TZ                         = var.timezone
    JELLYFIN_PublishedServerUrl = "${var.hostname}/jellyfin"
  }
}

module "jellyfin" {
  source         = "../../../../10-services-generic/docker-service"
  container_name = local.container_name
  image          = local.image
  tag            = local.tag
  volumes        = local.jellyfin_volumes
  env_vars       = local.jellyfin_env_vars
  ports          = local.internal_ports
  devices        = local.jellyfin_devices
  networks       = var.networks
  monitoring     = var.monitoring
  restart_policy = "always"
}

output "service_definition" {
  description = "Service definition for integration with networking modules"
  value = {
    name         = local.container_name
    primary_port = 8096
    endpoint     = "http://${local.container_name}:8096"
    subdomains   = ["jellyfin"]
    publish_via  = "reverse_proxy"
    proxied      = false
  }
}
