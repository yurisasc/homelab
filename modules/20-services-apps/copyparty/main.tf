variable "image_tag" {
  description = "The tag for the copyparty container image"
  type        = string
  default     = "latest"
}

variable "fileshare_path" {
  description = "Path to the top folder of the file share"
  type        = string
}

variable "config_path" {
  description = "Path to the configuration files for copyparty"
  type        = string
}

variable "networks" {
  description = "List of networks to which the container should be attached"
  type        = list(string)
  default     = []
}

variable "puid" {
  description = "User ID to run the container as"
  type        = string
  default     = "1000"
}

variable "pgid" {
  description = "Group ID to run the container as"
  type        = string
  default     = "1000"
}

locals {
  container_name = "copyparty"
  image          = "copyparty/ac"
  tag            = var.image_tag
  monitoring     = true
  internal_port  = 3923
  user           = "${var.puid}:${var.pgid}"
  volumes = [
    {
      host_path      = var.config_path
      container_path = "/cfg"
      read_only      = false
    },
    {
      host_path      = var.fileshare_path
      container_path = "/w"
      read_only      = false
    }
  ]
  env_vars = {
    LD_PRELOAD       = "/usr/lib/libmimalloc-secure.so.2"
    PYTHONUNBUFFERED = "1"
  }
}

module "copyparty" {
  source            = "../../10-services-generic/docker-service"
  container_name    = local.container_name
  image             = local.image
  tag               = local.tag
  user              = local.user
  volumes           = local.volumes
  env_vars          = local.env_vars
  networks          = var.networks
  monitoring        = local.monitoring
  destroy_grace_seconds = 15
  ports             = [
    {
      internal = local.internal_port
      external = local.internal_port
      protocol = "tcp"
    }
  ]
}

output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = local.internal_port
    endpoint     = "http://${local.container_name}:${local.internal_port}"
    subdomains   = ["drive"]
    publish_via  = "tunnel"
  }
}
