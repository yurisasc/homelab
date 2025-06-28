# Glance Module

This module deploys [Glance](https://glanceapp.io/), a dashboard application, as a Docker container in the homelab environment.

## Overview

The Glance module:

- Deploys the `glanceapp/glance` Docker container
- Persists configuration to a volume on the host
- Provides service definition for integration with networking modules

## Usage

```hcl
module "glance" {
  source      = "./modules/20-services-apps/glance"
  volume_path = "/path/to/volumes/glance"
  networks    = ["homelab-network"]
}
```

## Variables

| Variable      | Description                                                | Type           | Default    |
| ------------- | ---------------------------------------------------------- | -------------- | ---------- |
| `image_tag`   | Tag of the Glance image to use                             | `string`       | `"latest"` |
| `volume_path` | Host path for Glance data volume                           | `string`       | -          |
| `networks`    | List of networks to which the container should be attached | `list(string)` | -          |

## Outputs

| Output               | Description                                                |
| -------------------- | ---------------------------------------------------------- |
| `service_definition` | Service definition for integration with networking modules |

## Service Definition

This module outputs a service definition that is used by the networking modules to expose the service.

```hcl
{
  name         = "glance"
  primary_port = 4921
  endpoint     = "http://glance:4921"
  subdomains   = ["glance"]
  publish_via  = "tunnel"  # Only publish through Cloudflare tunnel
}
```

## Data Persistence

Glance stores its configuration in the `/app/config` directory inside the container. This is mapped to a volume on the host at `${volume_path}/config`.

## Integration with Networking Modules

This service is configured to be exposed through a Cloudflare tunnel for secure remote access, set by `publish_via = "tunnel"`.

## Example Integration in Main Configuration

```hcl
module "glance" {
  source      = "./modules/20-services-apps/glance"
  volume_path = module.system_globals.volume_host
  networks    = [module.services.homelab_docker_network_name]
}

# The service definition is automatically included in the services output
module "services" {
  source = "./modules/services"
  # ...
  service_definitions = [
    module.glance.service_definition,
    # Other service definitions
  ]
}
```
