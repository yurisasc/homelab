// ActualBudget module for budgeting
// This module configures an ActualBudget container with the specified volumes

locals {
  container_name = var.container_name != "" ? var.container_name : "actualbudget"
  image_tag      = var.image_tag != "" ? var.image_tag : "latest"

  default_env_vars = {
    TZ = var.timezone
    PUID = var.puid
    PGID = var.pgid
  }

  default_volumes = [
    {
      container_path = "/data"
      host_path      = var.data_volume_path
      read_only      = false
    }
  ]
}

module "actualbudget" {
  source = "../../10-services-generic/docker-service"

  container_name = var.container_name
  image          = "actualbudget/actual-server"
  tag            = var.image_tag
  
  // Environment variables
  env_vars = local.default_env_vars

  // Port mapping
  ports = [
    {
      internal = 5006
      external = var.port
      protocol = "tcp"
    }
  ]

  // Volume mapping
  volumes = local.default_volumes

  // Enable monitoring for the container via Watchtower
  monitoring = var.monitoring

  networks = var.networks
}
