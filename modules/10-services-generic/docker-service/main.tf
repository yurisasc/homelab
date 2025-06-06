// Generic Docker service module
// Creates and manages a Docker container with configurable options

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = ">= 3.0.0"
    }
  }
}

locals {
  network_mode  = var.network_mode
  container_name = var.container_name
  image_name    = "${var.image}:${var.tag}"
  
  // Prepare ports configuration
  ports_config = [
    for port in var.ports : {
      internal = port.internal
      external = port.external
      protocol = port.protocol
    }
  ]
  
  // Prepare volumes configuration
  volumes_config = [
    for volume in var.volumes : {
      host_path      = volume.host_path
      container_path = volume.container_path
      read_only      = volume.read_only
    }
  ]
  
  // Define monitoring labels if enabled
  monitoring_labels = var.monitoring ? {
    "com.centurylinklabs.watchtower.enable" = "true"
  } : {}
  
  // Merge provided labels with monitoring labels
  merged_labels = merge(var.labels, local.monitoring_labels)
}

// Pull the Docker image
resource "docker_image" "service_image" {
  name         = local.image_name
  keep_locally = var.keep_image_locally
  pull_triggers = [var.tag]
}

// Create the Docker container
resource "docker_container" "service_container" {
  name  = local.container_name
  image = docker_image.service_image.image_id
  
  restart = var.restart_policy
  
  # Set the network mode (bridge, host, etc.)
  network_mode = local.network_mode
  
  # Dynamically configure ports based on the provided list
  dynamic "ports" {
    for_each = local.ports_config
    content {
      internal = ports.value.internal
      external = ports.value.external
      protocol = ports.value.protocol
    }
  }
  
  # Dynamically configure networks based on the provided list
  dynamic "networks_advanced" {
    for_each = var.networks
    content {
      name = networks_advanced.value
    }
  }
  
  # Dynamically configure volumes based on the provided list
  dynamic "volumes" {
    for_each = local.volumes_config
    content {
      host_path      = volumes.value.host_path
      container_path = volumes.value.container_path
      read_only      = volumes.value.read_only
    }
  }
  
  # Configure environment variables - map to array of strings
  env = [for k, v in var.env_vars : "${k}=${v}"]
  
  # Set container labels
  dynamic "labels" {
    for_each = local.merged_labels
    content {
      label = labels.key
      value = labels.value
    }
  }
  
  # Add container healthcheck if configured
  dynamic "healthcheck" {
    for_each = var.healthcheck != null ? [var.healthcheck] : []
    content {
      test         = healthcheck.value.test
      interval     = healthcheck.value.interval
      timeout      = healthcheck.value.timeout
      start_period = healthcheck.value.start_period
      retries      = healthcheck.value.retries
    }
  }
  
  # Set resource limits if specified
  memory               = var.memory_limit
  memory_swap          = var.memory_swap_limit
  cpu_shares           = var.cpu_shares
  
  # Other container options
  dns             = var.dns
  dns_search      = var.dns_search
  hostname        = var.hostname
  domainname      = var.domainname
  user            = var.user
  working_dir     = var.working_dir
  command         = var.command
  entrypoint      = var.entrypoint
  privileged      = var.privileged
  
  # Set log options
  log_driver = var.log_driver
  log_opts   = var.log_opts
}
