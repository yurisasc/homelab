# Sabnzbd Module

This module deploys Sabnzbd as a Docker container and outputs a non-published service definition.

## Overview

- Container: `sabnzbd` (LinuxServer.io)
- Web UI on TCP 8080
- Mounts `/config` and `/downloads`

## Usage

```hcl
module "sabnzbd" {
  source         = "./modules/20-services-apps/sabnzbd"
  volume_path    = "/srv/appdata/sabnzbd" # host path for app config
  downloads_path = "/srv/data/usenet"     # host path for usenet downloads
  networks       = [module.media_docker_network.name, module.homelab_docker_network.name]
}
```

## Variables

| Variable         | Description                                 | Type           | Default |
| ---------------- | ------------------------------------------- | -------------- | ------- |
| `volume_path`    | Base directory for Sabnzbd config            | `string`       | -       |
| `downloads_path` | Directory for downloads mounted at /downloads | `string`      | -       |
| `networks`       | List of networks to attach                   | `list(string)` | `[]`    |

## Outputs

| Output               | Description                    |
| -------------------- | ------------------------------ |
| `service_definition` | Service definition for integration with networking modules |

## Service Definition

This module outputs a service definition that is used by the networking modules. Sabnzbd is not published externally.

```hcl
{
  name         = "sabnzbd"
  primary_port = 8080
  endpoint     = "http://sabnzbd:8080"
}
```

## Environment Variables

- `TZ`, `PUID`, and `PGID` are injected automatically via system globals in the generic docker-service module.

## Data Persistence

- `/config` -> `${volume_path}`
- `/downloads` -> `${downloads_path}`
- Ensure host paths exist and permissions align with the container user.

## Networking

- Attaches to `networks` (typically media and homelab). Not published externally; accessible internally.

## Dependencies

- No explicit inter-container dependencies. Healthcheck ensures readiness.

## Example Integration in Main Configuration

```hcl
# In services/main.tf
module "sabnzbd" {
  source         = "${local.module_dir}/20-services-apps/sabnzbd"
  volume_path    = "${local.volume_host}/sabnzbd"
  downloads_path = "${local.data_host}/usenet"
  networks       = [module.media_docker_network.name, module.homelab_docker_network.name]
}
```

The service definition is exported by the `services` module as `module.services.service_definitions` and consumed by networking modules in the root `main.tf`.
