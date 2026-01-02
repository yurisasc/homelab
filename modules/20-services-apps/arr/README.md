# *arr Stack Module

This module deploys the *arr media stack components as Docker containers and provides a service definition for Jellyseerr to be published via your reverse proxy.

## Overview

The *arr Stack module:

- Deploys the following containers:
  - `sonarr`: TV series management
  - `radarr`: Movie management
  - `lidarr`: Music management
  - `bazarr`: Subtitle management
  - `prowlarr`: Indexer management
  - `jellyseerr`: Media request management (published via reverse proxy)
  - `unpackerr`: Archive extraction
  - `cleanuparr`: Queue cleanup helper
  - `decluttarr`: Torrent management helper
- Shares a common `/data` mount for consistent media management
- Integrates with a standalone `flaresolverr` instance via the media network
- Provides service definition for Jellyseerr integration with networking modules

## Usage

```hcl
module "arr" {
  source         = "./modules/20-services-apps/arr"
  volume_path    = "/srv/appdata/arr"
  data_path      = "/srv/data"
  downloads_path = "/srv/data/torrents"
  networks       = [module.media_docker_network.name]
  proxy_networks = [module.homelab_docker_network.name]
}
```

## Variables

| Variable           | Description                                                                     | Type           | Default         |
| ------------------ | ------------------------------------------------------------------------------- | -------------- | --------------- |
| `volume_path`      | Base directory for config volumes for the *arr stack                            | `string`       | -               |
| `data_path`        | Base directory for media/data mounted at `/data`                                | `string`       | -               |
| `downloads_path`   | Directory for downloads mounted at `/data/torrents` (Unpackerr)                 | `string`       | -               |
| `networks`         | Networks to attach all containers to                                            | `list(string)` | `[]`            |
| `proxy_networks`   | Extra networks attached only to published services (Jellyseerr)                 | `list(string)` | `[]`            |
| `qbittorrent_host` | Hostname to reach qBittorrent (use `gluetun` when qBittorrent shares Gluetun)   | `string`       | `"qbittorrent"` |

## Outputs

| Output               | Description                                                |
| -------------------- | ---------------------------------------------------------- |
| `service_definition` | Service definition for integration with networking modules |

## Service Definition

This module outputs a service definition for Jellyseerr that is used by the networking modules to expose the service.

```hcl
{
  name         = "jellyseerr"
  primary_port = 5055
  endpoint     = "http://jellyseerr:5055"
  subdomains   = ["req"]
  publish_via  = "reverse_proxy"
  proxied      = true
}
```

## Environment Variables

This module reads secrets via the `dotenv` provider from a `.env` file in the module directory. See `.env.example` for required keys like `SONARR_API_KEY`, `RADARR_API_KEY`, and `QBITTORRENT_PASSWORD`.

## Data Persistence

- Each app stores configuration under `${volume_path}/<app>` on the host.
- Media library and downloads are accessed under `/data` inside containers, pointing to `data_path` on the host.

## Integration with Networking Modules

Jellyseerr is configured to be exposed through the Caddy reverse proxy, set by `publish_via = "reverse_proxy"`.

## Example Integration in Main Configuration

```hcl
module "arr" {
  source         = "${local.module_dir}/20-services-apps/arr"
  volume_path    = "${local.volume_host}/arr"
  data_path      = local.data_host
  downloads_path = "${local.data_host}/torrents"
  networks       = [module.media_docker_network.name]
  proxy_networks = [module.homelab_docker_network.name]
  qbittorrent_host = "gluetun"
}
```
