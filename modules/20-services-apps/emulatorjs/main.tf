// EmulatorJS module for retro game emulation
// This module configures an EmulatorJS container with the specified volumes

locals {
  container_name = var.container_name != "" ? var.container_name : "emulatorjs"
  image_tag      = var.image_tag != "" ? var.image_tag : "latest"
  
  default_env_vars = {
    TZ           = var.timezone
  }
  
  // Merge default env vars with any additional ones provided
  env_vars = merge(local.default_env_vars, var.additional_env_vars)
  
  // Default volumes for EmulatorJS
  default_volumes = [
    {
      host_path      = var.config_volume_path
      container_path = "/config"
      read_only      = false
    },
    {
      host_path      = var.data_volume_path
      container_path = "/data"
      read_only      = false
    }
  ]
  
  // Merge default volumes with any additional ones provided
  volumes = concat(local.default_volumes, var.additional_volumes)
}

// Use the generic docker-service module to deploy EmulatorJS
module "emulatorjs" {
  source = "../../10-services-generic/docker-service"

  container_name  = local.container_name
  image           = "linuxserver/emulatorjs"
  tag             = local.image_tag
  
  restart_policy  = var.restart_policy
  network_mode    = "bridge"
  
  env_vars        = local.env_vars
  volumes         = local.volumes
  
  labels          = var.labels
  
  // Default ports for EmulatorJS
  ports           = [
    {
      internal    = 3000
      external    = var.config_port
      protocol    = "tcp"
    },
    {
      internal    = 80
      external    = var.frontend_port
      protocol    = "tcp"
    },
    {
      internal    = 4001
      external    = var.backend_port
      protocol    = "tcp"
    }
  ]
  
  // Enable monitoring for the container via Watchtower
  monitoring      = var.monitoring
}
