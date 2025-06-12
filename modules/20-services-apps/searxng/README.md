# SearxNG Module

This module deploys [SearxNG](https://searx.github.io/searx/), a privacy-respecting metasearch engine, as a Docker container in the homelab environment.

## Overview

The SearxNG module:

- Deploys the `searxng/searxng` Docker container
- Persists configuration data to a volume on the host
- Provides service definition for integration with networking modules

## Usage

```hcl
module "searxng" {
  source      = "./modules/20-services-apps/searxng"
  volume_path = "/path/to/volumes/searxng"
  networks    = ["homelab-network"]
}
```

## Variables

| Variable      | Description                                                | Type           | Default    |
| ------------- | ---------------------------------------------------------- | -------------- | ---------- |
| `image_tag`   | Tag of the SearxNG image to use                            | `string`       | `"latest"` |
| `volume_path` | Host path for SearxNG configuration volume                 | `string`       | -          |
| `networks`    | List of networks to which the container should be attached | `list(string)` | `[]`       |

## Outputs

| Output               | Description                                   |
| -------------------- | --------------------------------------------- |
| `service_definition` | Service definition for integration with networking modules |

## Service Definition

This module outputs a service definition that is used by the networking modules to expose the service.

```hcl
{
  name         = "searxng"
  primary_port = 8080
  endpoint     = "http://searxng:8080"
  subdomains   = ["search"]
  publish_via  = "tunnel"  # Only publish through Cloudflare tunnel
}
```

## Data Persistence

SearxNG stores its configuration in a single volume:

- Configuration: `/etc/searxng` in the container, mapped to `${volume_path}/config` on the host

## Integration with Networking Modules

This service is configured to be exposed through a Cloudflare tunnel for secure remote access, set by `publish_via = "tunnel"`.

## Example Integration in Main Configuration

```hcl
module "searxng" {
  source      = "./modules/20-services-apps/searxng"
  volume_path = module.system_globals.volume_host
  networks    = [module.services.homelab_docker_network_name]
}

# The service definition is automatically included in the services output
module "services" {
  source = "./modules/services"
  # ...
  service_definitions = [
    module.searxng.service_definition,
    # Other service definitions
  ]
}
```
