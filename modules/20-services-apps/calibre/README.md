# Calibre Module

This module deploys [Calibre Web Automated](https://hub.docker.com/r/crocodilestick/calibre-web-automated), a web app for browsing, reading, and managing eBooks, as a Docker container in the homelab environment.

## Overview

The Calibre module:

- Deploys a Docker container:
  - `calibre-web-automated`: The main Calibre Web application with automation features
- Creates a dedicated Docker network (`calibre-network`) for container communication
- Persists data to volumes on the host
- Provides service definition for integration with networking modules

## Usage

```hcl
module "calibre" {
  source      = "./modules/20-services-apps/calibre"
  volume_path = "/path/to/volumes"
  networks    = ["homelab-network"]
  user_id     = "1000"
  group_id    = "1000"
  timezone    = "UTC"
}
```

## Variables

| Variable      | Description                                                     | Type           | Default    |
| ------------- | --------------------------------------------------------------- | -------------- | ---------- |
| `image_tag`   | Tag of the Calibre Web image to use                             | `string`       | `"latest"` |
| `volume_path` | Host path for Calibre data volumes                              | `string`       | -          |
| `networks`    | List of additional networks to which Calibre should be attached | `list(string)` | `[]`       |
| `user_id`     | User ID for container permissions                               | `string`       | `"1000"`   |
| `group_id`    | Group ID for container permissions                              | `string`       | `"1000"`   |
| `timezone`    | Timezone for the container                                      | `string`       | `"UTC"`    |

## Outputs

| Output               | Description                                                |
| -------------------- | ---------------------------------------------------------- |
| `service_definition` | Service definition for integration with networking modules |

## Service Definition

This module outputs a service definition that is used by the networking modules to expose the service.

```hcl
{
  name         = "calibre-web-automated"
  primary_port = 8083
  endpoint     = "http://calibre-web-automated:8083"
  subdomains   = ["calibre"]
  publish_via  = "reverse_proxy"
  proxied      = false
}
```

## Docker Mods

This module includes the Calibre Docker mod to add Calibre functionality to the container:
- `lscr.io/linuxserver/mods:universal-calibre-v7.16.0`

## Data Persistence

Calibre stores its data in three main volumes:

1. Configuration data: `/config` in the container, mapped to `${volume_path}/config` on the host
2. Book ingest directory: `/cwa-book-ingest` in the container, mapped to `${volume_path}/ingest` on the host
3. Calibre library: `/calibre-library` in the container, mapped to `${volume_path}/library` on the host

## Networking

The Calibre container is attached to any additional networks specified in the `networks` variable, allowing it to communicate with other services in the homelab.

## Integration with Networking Modules

This service is configured to be exposed through the Caddy reverse proxy, set by `publish_via = "reverse_proxy"`.

## Example Integration in Main Configuration

```hcl
module "calibre" {
  source      = "./modules/20-services-apps/calibre"
  volume_path = module.system_globals.volume_host
  networks    = [module.services.homelab_docker_network_name]
  user_id     = module.system_globals.user_id
  group_id    = module.system_globals.group_id
  timezone    = module.system_globals.timezone
}

# The service definition is automatically included in the services output
module "services" {
  source = "./modules/services"
  # ...
  service_definitions = [
    module.calibre.service_definition,
    # Other service definitions
  ]
}
```
