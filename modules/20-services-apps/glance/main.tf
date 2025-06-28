variable "image_tag" {
  description = "Tag of the Glance image to use"
  type        = string
  default     = "latest"
}

variable "volume_path" {
  description = "Host path for Glance data volume"
  type        = string
}

variable "networks" {
  description = "List of networks to which the container should be attached"
  type        = list(string)
}

locals {
  container_name = "glance"
  image          = "glanceapp/glance"
  image_tag      = var.image_tag != "" ? var.image_tag : "latest"
  monitoring     = true
  host_port      = 8080
  subdomains     = ["glance"]
  default_volumes = [
    {
      container_path = "/app/config"
      host_path      = "${var.volume_path}/config"
      read_only      = false
    },
  ]
}

module "glance" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.container_name
  image          = local.image
  tag            = local.image_tag
  volumes        = local.default_volumes
  networks       = var.networks
  monitoring     = local.monitoring
}

output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = local.host_port
    endpoint     = "http://${local.container_name}:${local.host_port}"
    subdomains   = local.subdomains
    publish_via  = "tunnel"
  }
}
