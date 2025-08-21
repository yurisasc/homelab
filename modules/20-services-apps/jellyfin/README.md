# Jellyfin Module

This module deploys Jellyfin as a Docker container and outputs a service definition to be published via your reverse proxy.

## Overview

- Container: `jellyfin` (LinuxServer.io)
- TCP 8096 for HTTP UI; UDP 7359/1900 for discovery/DLNA
- Config and media volumes mapped via variables

## Usage

```hcl
module "jellyfin" {
  source      = "./modules/20-services-apps/jellyfin"
  volume_path = "/srv/appdata/jellyfin" # host path for Jellyfin config
  data_path   = "/srv/data"             # host media root, mounted as /data
  networks    = [module.media_docker_network.name, module.homelab_docker_network.name]
}
```

## Variables

| Variable      | Description                                   | Type           | Default |
| ------------- | --------------------------------------------- | -------------- | ------- |
| `volume_path` | Base directory for Jellyfin config             | `string`       | -       |
| `data_path`   | Base directory for media data mounted at /data | `string`       | -       |
| `networks`    | List of networks to attach                     | `list(string)` | `[]`    |

## Outputs

| Output               | Description                                  |
| -------------------- | -------------------------------------------- |
| `service_definition` | Service definition for integration with networking modules |

## Service Definition

This module outputs a service definition that is used by the networking modules to expose the service.

```hcl
{
  name         = "jellyfin"
  primary_port = 8096
  endpoint     = "http://jellyfin:8096"
  subdomains   = ["stream"]
  publish_via  = "reverse_proxy"
  proxied      = false
}
```

## Environment Variables (.env)

This module optionally reads `HOSTNAME` from `.env` if you choose to publish a fixed external URL (see commented example in `main.tf`).

- `HOSTNAME` — your public domain (e.g., example.com). Used only if you enable `JELLYFIN_PublishedServerUrl`.

Note: `TZ`, `PUID`, and `PGID` are provided automatically by the generic docker-service module via system globals.

## Data Persistence

- `/config` -> `${volume_path}`
- `/data`   -> `${data_path}`

Ensure the host paths exist and are writable by the container user.

## Dependencies

- No explicit inter-container dependencies. Healthcheck ensures readiness.
- UDP ports are exposed for discovery/DLNA.

## Integration with Networking Modules

This service is configured to be exposed through the Caddy reverse proxy, set by `publish_via = "reverse_proxy"`.

## Example Integration in Main Configuration

```hcl
# In services/main.tf
module "jellyfin" {
  source      = "${local.module_dir}/20-services-apps/jellyfin"
  volume_path = "${local.volume_host}/jellyfin"
  data_path   = "${local.data_host}/media"
  networks    = [module.media_docker_network.name, module.homelab_docker_network.name]
}
```

The service definition is exported by the `services` module as `module.services.service_definitions` and consumed by networking modules in the root `main.tf`.
