# Portainer Module

This module deploys [Portainer](https://www.portainer.io/), a lightweight management UI that allows you to easily manage your different Docker environments.

## Overview

The Portainer module:

- Deploys one Docker container: `portainer`.
- Mounts the Docker socket to allow Portainer to manage the Docker environment.
- Persists Portainer data to a volume on the host.
- Provides a service definition for integration with networking modules.

## Usage

```hcl
module "portainer" {
  source      = "./modules/20-services-apps/portainer"
  volume_path = "/path/to/volumes/portainer"
  networks    = ["homelab-network"]
}
```

## Variables

| Variable      | Description                                                      |
| ------------- | ---------------------------------------------------------------- |
| `image_tag`   | Tag of the Portainer image to use                                |
| `volume_path` | Host path for Portainer data volume                              |
| `networks`    | List of additional networks to which Portainer should be attached |

## Outputs

| Output               | Description                                                |
| -------------------- | ---------------------------------------------------------- |
| `service_definition` | Service definition for integration with networking modules |

## Service Definition

This module outputs a service definition that is used by the networking modules to expose the service.

```hcl
{
  name         = "portainer"
  primary_port = 9000
  endpoint     = "http://portainer:9000"
  subdomains   = ["portainer"]
  publish_via  = "reverse_proxy"
}
```

## Data Persistence

Portainer stores its data in a single volume:

1. Portainer data: `/data` in the container, mapped to `${volume_path}/data` on the host.

It also mounts the Docker socket from `/var/run/docker.sock` on the host to `/var/run/docker.sock` in the container to manage Docker.

## Example Integration in Main Configuration

```hcl
module "portainer" {
  source      = "./modules/20-services-apps/portainer"
  volume_path = "${module.system_globals.volume_host}/portainer"
  networks    = [module.services.homelab_docker_network_name]
}

# The service definition is automatically included in the services output
module "services" {
  source = "./modules/services"
  # ...
  service_definitions = [
    module.portainer.service_definition,
    # Other service definitions
  ]
}
```
