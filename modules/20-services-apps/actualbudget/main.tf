variable "image_tag" {
  description = "Tag of the ActualBudget image to use"
  type        = string
  default     = "latest"
}

variable "volume_path" {
  description = "Host path for ActualBudget data volume"
  type        = string
}

variable "networks" {
  description = "List of networks to which the container should be attached"
  type        = list(string)
}

locals {
  container_name = "actualbudget"
  image          = "actualbudget/actual-server"
  image_tag      = var.image_tag != "" ? var.image_tag : "latest"
  monitoring     = true
  exposed_port   = 5006
  subdomains     = ["budget"]
  default_volumes = [
    {
      container_path = "/data"
      host_path      = "${var.volume_path}/data"
      read_only      = false
    }
  ]
}

module "actualbudget" {
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
    subdomains    = local.subdomains
    publish_via   = "tunnel"
  }
}
