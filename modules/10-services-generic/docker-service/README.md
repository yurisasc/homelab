# Generic Docker Service Module

This is a reusable OpenTofu module for deploying Docker containers with configurable options. It serves as the foundation for specific application modules in this homelab project.

## Features

- Pull and manage Docker images
- Configure container networking, ports, and volumes
- Set environment variables and labels
- Configure resource limits and constraints
- Set up health checks
- Support for container logging options

## Usage

This module is typically called by application-specific modules rather than used directly, but can be used as follows:

```hcl
module "my_service" {
  source = "../../10-services-generic/docker-service"

  container_name = "my-service"
  image          = "organization/image"
  tag            = "latest"
  
  restart_policy = "unless-stopped"
  network_mode   = "bridge"
  
  // Port mappings
  ports = [
    {
      internal = 8080
      external = 8080
      protocol = "tcp"
    }
  ]
  
  // Volume mappings
  volumes = [
    {
      host_path      = "/path/on/host"
      container_path = "/path/in/container"
      read_only      = false
    }
  ]
  
  // Environment variables
  env_vars = {
    VARIABLE_NAME = "value"
  }
  
  // Container labels
  labels = {
    "com.example.description" = "My service description"
  }
  
  // Enable Watchtower updates
  monitoring = true
}
```

## Required Providers

This module requires the Docker provider to be configured in your root module:

```hcl
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = ">= 3.0.0"
    }
  }
}
```

## Inputs

See the `variables.tf` file for a complete list of input variables and their descriptions.

## Outputs

| Name | Description |
|------|-------------|
| container_name | Name of the Docker container |
| container_id | ID of the Docker container |
| image_id | ID of the Docker image |
| ip_address | IP address of the container (if applicable) |
| container_ports | Published ports of the container |
