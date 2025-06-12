# NTFY Module

This module deploys [NTFY](https://ntfy.sh/), a simple HTTP-based pub-sub notification service, as a Docker container in the homelab environment.

## Overview

The NTFY module:

- Deploys the `binwiederhier/ntfy` Docker container
- Persists configuration and cache data to volumes on the host
- Provides service definition for integration with networking modules

## Usage

```hcl
module "ntfy" {
  source      = "./modules/20-services-apps/ntfy"
  volume_path = "/path/to/volumes/ntfy"
  networks    = ["homelab-network"]
}
```

## Variables

| Variable      | Description                                                | Type           | Default    |
| ------------- | ---------------------------------------------------------- | -------------- | ---------- |
| `image_tag`   | Tag of the NTFY image to use                               | `string`       | `"latest"` |
| `volume_path` | Host path for NTFY data volumes                            | `string`       | -          |
| `networks`    | List of networks to which the container should be attached | `list(string)` | -          |

## Outputs

| Output               | Description                                                |
| -------------------- | ---------------------------------------------------------- |
| `service_definition` | Service definition for integration with networking modules |

## Service Definition

This module outputs a service definition that is used by the networking modules to expose the service.

```hcl
{
  name         = "ntfy"
  primary_port = 80
  endpoint     = "http://ntfy:80"
  subdomains   = ["ntfy"]
  publish_via  = "reverse_proxy"  # Expose via Caddy reverse proxy
  proxied      = true             # Proxy through Cloudflare
}
```

## Data Persistence

NTFY stores its data in two volumes:

1. Configuration: `/etc/ntfy` in the container, mapped to `${volume_path}/app` on the host
2. Cache data: `/var/cache/ntfy` in the container, mapped to `${volume_path}/cache` on the host

## Integration with Networking Modules

This service is configured to be exposed through the Caddy reverse proxy, set by `publish_via = "reverse_proxy"`. The `proxied = true` setting ensures that the DNS record is proxied through Cloudflare.

## Example Integration in Main Configuration

```hcl
module "ntfy" {
  source      = "./modules/20-services-apps/ntfy"
  volume_path = module.system_globals.volume_host
  networks    = [module.services.homelab_docker_network_name]
}

# The service definition is automatically included in the services output
module "services" {
  source = "./modules/services"
  # ...
  service_definitions = [
    module.ntfy.service_definition,
    # Other service definitions
  ]
}
```
