terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

resource "docker_network" "this" {
  name        = var.name
  driver      = var.driver
  internal    = var.internal
  attachable  = var.attachable
  ipam_driver = var.ipam_driver

  dynamic "ipam_config" {
    for_each = var.subnet != "" ? [1] : []
    content {
      subnet      = var.subnet
      gateway     = var.gateway
      ip_range    = var.ip_range
      aux_address = var.aux_address
    }
  }

  options = var.options
}
