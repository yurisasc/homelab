variable "image_tag" {
  description = "Tag of the fossflow image to use"
  type        = string
  default     = "latest"
}

variable "volume_path" {
  description = "Host path for fossflow data volume"
  type        = string
}

variable "networks" {
  description = "List of networks to which the container should be attached"
  type        = list(string)
  default     = []
}

variable "host_port" {
  description = "Host port to publish fossflow on"
  type        = number
  default     = 31845
}

variable "enable_server_storage" {
  description = "Whether to enable server storage"
  type        = bool
  default     = true
}

variable "enable_git_backup" {
  description = "Whether to enable git backup"
  type        = bool
  default     = false
}

locals {
  container_name = "fossflow"
  image          = "stnsmith/fossflow"
  image_tag      = var.image_tag != "" ? var.image_tag : "latest"
  monitoring     = true
  internal_port  = 80
  subdomains     = ["fossflow"]

  ports = [
    {
      internal = local.internal_port
      external = var.host_port
      protocol = "tcp"
    }
  ]

  volumes = [
    {
      host_path      = "${var.volume_path}/diagrams"
      container_path = "/data/diagrams"
      read_only      = false
    }
  ]

  env_vars = {
    NODE_ENV              = "production"
    ENABLE_SERVER_STORAGE = tostring(var.enable_server_storage)
    STORAGE_PATH          = "/data/diagrams"
    ENABLE_GIT_BACKUP     = tostring(var.enable_git_backup)
  }
}

module "fossflow" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.container_name
  image          = local.image
  tag            = local.image_tag
  volumes        = local.volumes
  ports          = local.ports
  env_vars       = local.env_vars
  networks       = var.networks
  monitoring     = local.monitoring
}

output "service_definition" {
  description = "Service definition for fossflow (tunnel)"
  value = {
    name         = local.container_name
    primary_port = local.internal_port
    endpoint     = "http://${local.container_name}:${local.internal_port}"
    subdomains   = local.subdomains
    publish_via  = "tunnel"
    proxied      = true
  }
}
