// Watchtower module for automatic Docker container updates
// This module configures a Watchtower container that monitors and updates other containers

locals {
  container_name = var.container_name != "" ? var.container_name : "watchtower"
  image_tag      = var.image_tag != "" ? var.image_tag : "latest"
  
  default_env_vars = {
    TZ                           = var.timezone
    WATCHTOWER_CLEANUP           = var.cleanup
    WATCHTOWER_POLL_INTERVAL     = var.poll_interval
    WATCHTOWER_INCLUDE_STOPPED   = var.include_stopped
    WATCHTOWER_REVIVE_STOPPED    = var.revive_stopped
    WATCHTOWER_ROLLING_RESTART   = var.rolling_restart
    WATCHTOWER_NOTIFICATION_URL  = var.notification_url
    WATCHTOWER_NOTIFICATIONS     = var.enable_notifications ? "shoutrrr" : ""
  }
  
  // Merge default env vars with any additional ones provided
  env_vars = merge(local.default_env_vars, var.additional_env_vars)
  
  // Default volumes for Docker socket access
  default_volumes = [
    {
      host_path      = "/var/run/docker.sock"
      container_path = "/var/run/docker.sock"
      read_only      = true
    }
  ]
  
  // Merge default volumes with any additional ones provided
  volumes = concat(local.default_volumes, var.additional_volumes)
}

// Use the generic docker-service module to deploy Watchtower
module "watchtower" {
  source = "../../10-services-generic/docker-service"

  container_name  = local.container_name
  image           = "containrrr/watchtower"
  tag             = local.image_tag
  
  restart_policy  = var.restart_policy
  network_mode    = "bridge"
  
  env_vars        = local.env_vars
  volumes         = local.volumes
  
  labels          = var.labels
  
  // Watchtower doesn't typically expose ports but we'll include the option
  ports           = var.ports
  
  // Add monitoring label if enabled
  monitoring      = var.monitoring
  
  depends_on      = []
}
