
variable "image_tag" {
  description = "The tag for the portainer container image"
  type        = string
  default     = "latest"
}

variable "volume_path" {
  description = "Base directory for volumes"
  type        = string
}

variable "networks" {
  description = "List of networks to which the container should be attached"
  type        = list(string)
  default     = []
}

locals {
  container_name = "portainer"
  image          = "portainer/portainer-ce"
  tag            = var.image_tag
  internal_port  = 9000
  exposed_port   = 9000

  # Define volumes
  volumes = [
    {
      host_path      = "/var/run/docker.sock"
      container_path = "/var/run/docker.sock"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/data"
      container_path = "/data"
      read_only      = false
    }
  ]
}

# Create the portainer container
module "portainer" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.container_name
  image          = local.image
  tag            = local.tag
  volumes        = local.volumes
  networks       = var.networks
  ports = [
    {
      internal = local.internal_port
      external = local.exposed_port
      protocol = "tcp"
    },
  ]
}

output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = local.internal_port
    endpoint     = "http://${local.container_name}:${local.internal_port}"
  }
}
