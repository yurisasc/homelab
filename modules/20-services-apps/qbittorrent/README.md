# qBittorrent Module

This module deploys qBittorrent as a Docker container with the Vuetorrent UI mod.

## Overview

- Container: `qbittorrent` (LinuxServer.io) with `vuetorrent` mod
- Web UI on TCP 8080
- Mounts `/config` and `/data/torrents`

## Usage

Without Gluetun:

```hcl
module "qbittorrent" {
  source         = "./modules/20-services-apps/qbittorrent"
  volume_path    = "/srv/appdata/qbittorrent"
  downloads_path = "/srv/data/torrents"
  networks       = [module.media_docker_network.name]
}
```

With Gluetun (recommended for privacy):

```hcl
module "gluetun" {
  source      = "./modules/20-services-apps/gluetun"
  volume_path = "/srv/appdata/gluetun"
  networks    = [module.media_docker_network.name]
  # Optional: expose qBittorrent UI to the host via Gluetun
  # ports = [{ internal = 8080, external = 8080, protocol = "tcp" }]
}

module "qbittorrent" {
  source                 = "./modules/20-services-apps/qbittorrent"
  volume_path            = "/srv/appdata/qbittorrent"
  downloads_path         = "/srv/data/torrents"
  networks               = [module.media_docker_network.name]
  connect_via_gluetun    = true
  gluetun_container_name = "gluetun"
}
```

## Variables

| Variable                | Description                                                     | Type           | Default     |
| ----------------------- | --------------------------------------------------------------- | -------------- | ----------- |
| `volume_path`           | Base directory for qBittorrent config                           | `string`       | -           |
| `downloads_path`        | Directory for downloads mounted at /data/torrents               | `string`       | -           |
| `networks`              | Networks to attach (ignored when `connect_via_gluetun` is true) | `list(string)` | `[]`        |
| `connect_via_gluetun`   | Route qBittorrent through Gluetun (network_mode=container:gluetun) | `bool`      | `false`     |
| `gluetun_container_name`| Container name of the Gluetun instance                          | `string`       | `"gluetun"` |

## Outputs

| Output               | Description                         |
| -------------------- | ----------------------------------- |
| `service_definition` | Service definition for integration with networking modules |

## Service Definition

This module outputs a service definition that is used by the networking modules. qBittorrent is not published externally.

```hcl
{
  name         = "qbittorrent"
  primary_port = 8080
  endpoint     = "http://qbittorrent:8080"
}
```

## Environment Variables

- Defaults:
  - `WEBUI_PORT=8080`
  - `DOCKER_MODS=ghcr.io/gabe565/linuxserver-mod-vuetorrent`
- `TZ`, `PUID`, and `PGID` are injected by the generic docker-service module from system globals.

## Data Persistence

- `/config` -> `${volume_path}`
- `/data/torrents` -> `${downloads_path}`
- Ensure host paths exist and permissions align with the container user.

## Networking

- When `connect_via_gluetun = false`:
  - Container attaches to `networks` and exposes its Web UI internally at `http://qbittorrent:8080`.
- When `connect_via_gluetun = true`:
  - Container runs with `network_mode = container:<gluetun_container_name>`.
  - Do not publish ports on qBittorrent. If you need host access, publish `8080/tcp` on the Gluetun module instead.
  - Other containers should reach the Web UI at `http://gluetun:8080` when on the same Docker network as Gluetun.

## Dependencies

- No explicit inter-container dependencies. Healthcheck ensures readiness.

## Integration with Networking Modules

This service is not published externally. Its service definition is included in the aggregated `module.services.service_definitions` for internal discovery and potential future use by networking modules.

## Example Integration in Main Configuration

```hcl
# In services/main.tf
module "qbittorrent" {
  source         = "${local.module_dir}/20-services-apps/qbittorrent"
  volume_path    = "${local.volume_host}/qbittorrent"
  downloads_path = "${local.data_host}/torrents"
  networks               = [module.media_docker_network.name]
  connect_via_gluetun    = true
  gluetun_container_name = "gluetun"
}
```

The service definition is exported by the `services` module as `module.services.service_definitions` and consumed by networking modules in the root `main.tf`.
