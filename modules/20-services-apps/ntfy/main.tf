variable "image_tag" {
  description = "Tag of the ntfy image to use"
  type        = string
  default     = "latest"
}

variable "volume_path" {
  description = "Host path for ntfy data volume"
  type        = string
}

variable "networks" {
  description = "List of networks to which the container should be attached"
  type        = list(string)
}

locals {
  container_name = "ntfy"
  image          = "binwiederhier/ntfy"
  image_tag      = var.image_tag != "" ? var.image_tag : "latest"
  monitoring     = true
  exposed_port   = 80
  subdomains     = ["ntfy"]
  default_volumes = [
    {
      container_path = "/etc/ntfy"
      host_path      = "${var.volume_path}/app"
      read_only      = false
    },
    {
      container_path = "/var/cache/ntfy"
      host_path      = "${var.volume_path}/cache"
      read_only      = false
    }
  ]
}

module "ntfy" {
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
    primary_port = local.exposed_port
    endpoint     = "http://${local.container_name}:${local.exposed_port}"
    subdomains   = local.subdomains
    publish_via  = "tunnel"
    proxied      = true
  }
}
