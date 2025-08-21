# *arr Stack Module

This module deploys the *arr media stack components as Docker containers and provides a service definition for Jellyseerr to be published via your reverse proxy.

## Overview

The module includes the following containers:

- Sonarr (TV)
- Radarr (Movies)
- Lidarr (Music)
- Bazarr (Subtitles)
- Prowlarr (Indexers)
- Jellyseerr (Requests) — published via reverse proxy
- Flaresolverr (optional helper)
- Unpackerr (post-processing)
- Cleanuparr (cleanup helpers)
- Decluttarr (torrent queue cleanup helper)

All containers share a common `/data` mount (media root) and are attached to the media Docker network. Only Jellyseerr is also attached to the proxy network for reachability by Caddy.

## Usage

```hcl
module "arr" {
  source         = "./modules/20-services-apps/arr"
  volume_path    = "/srv/appdata/arr"         # host path for config directories
  data_path      = "/srv/data"                 # host media root, mounted as /data in containers
  downloads_path = "/srv/data/torrents"        # host downloads dir, mounted for unpackerr
  networks       = [module.media_docker_network.name]
  proxy_networks = [module.homelab_docker_network.name] # so Jellyseerr is reachable by Caddy
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

| Output               | Description                                                           |
| -------------------- | --------------------------------------------------------------------- |
| `service_definition` | Service definition for integration with networking modules             |

## Service Definition

This module outputs a service definition that is used by the networking modules to expose the service.

```hcl
{
  name         = "jellyseerr"
  primary_port = 5055
  endpoint     = "http://jellyseerr:5055"
  subdomains   = ["req"]
  publish_via  = "reverse_proxy"
  proxied      = false
}
```

## Environment Variables (.env)

This module reads secrets via the `dotenv` provider from a `.env` file located in this module directory. Use `.env.example` as a template.

Required/used keys:

- `SONARR_API_KEY` — for Unpackerr, Cleanuparr, Decluttarr
- `RADARR_API_KEY` — for Unpackerr, Cleanuparr, Decluttarr
- `LIDARR_API_KEY` — for Decluttarr
- `QBITTORRENT_USERNAME` — for Decluttarr
- `QBITTORRENT_PASSWORD` — for Cleanuparr and Decluttarr
- `LOG_LEVEL` — for Flaresolverr (optional)
- `LOG_HTML` — for Flaresolverr (optional)
- `CAPTCHA_SOLVER` — for Flaresolverr (optional)

Optional Decluttarr keys (override defaults as needed):

- `DECLUTTARR_LOG_LEVEL` (default: `INFO`)
- `DECLUTTARR_TEST_RUN` (default: `False`)
- `DECLUTTARR_REMOVE_TIMER` (default: `10`)
- `DECLUTTARR_REMOVE_FAILED` (default: `True`)
- `DECLUTTARR_REMOVE_FAILED_IMPORTS` (default: `True`)
- `DECLUTTARR_REMOVE_METADATA_MISSING` (default: `True`)
- `DECLUTTARR_REMOVE_MISSING_FILES` (default: `True`)
- `DECLUTTARR_REMOVE_ORPHANS` (default: `True`)
- `DECLUTTARR_REMOVE_SLOW` (default: `True`)
- `DECLUTTARR_REMOVE_STALLED` (default: `True`)
- `DECLUTTARR_REMOVE_UNMONITORED` (default: `True`)
- `DECLUTTARR_RUN_PERIODIC_RESCANS` (default: empty)
- `DECLUTTARR_PERMITTED_ATTEMPTS` (default: `3`)
- `DECLUTTARR_REMOVAL_QBIT_TAG` (default: `stalled`)
- `DECLUTTARR_MIN_DOWNLOAD_SPEED` (default: `100`)
- `DECLUTTARR_FAILED_IMPORT_MESSAGE_PATTERNS` (default: empty)
- `DECLUTTARR_IGNORED_DOWNLOAD_CLIENTS` (default: empty)

Note: `TZ`, `PUID`, `PGID` are injected automatically by the generic docker-service module from `modules/00-globals/system` and do not need to be in this `.env`.

## Data Persistence

- Each app stores configuration under `${volume_path}/<app>/...` mounted to `/config` (or as noted by the specific app).
- Media library and downloads are accessed under `/data` inside containers, pointing to `data_path` on the host.
- Unpackerr mounts `downloads_path` to `/data/torrents`.

## Networking

- All containers join `networks` (media network).
- Jellyseerr additionally joins `proxy_networks` for reverse proxy reachability.

## Dependencies

- No explicit inter-container dependencies are defined. Healthchecks are provided for stable orchestration.
- Decluttarr expects to reach `sonarr`, `radarr`, and `lidarr` via internal DNS and qBittorrent at `http://<qbittorrent_host>:8080`. When qBittorrent is routed via Gluetun using `network_mode=container:gluetun`, set `qbittorrent_host = "gluetun"`. Ensure they share the same Docker network.

## Integration with Networking Modules

This service is configured to be exposed through the Caddy reverse proxy, set by `publish_via = "reverse_proxy"`.

## Example Integration in Main Configuration

```hcl
# In services/main.tf
module "arr" {
  source         = "${local.module_dir}/20-services-apps/arr"
  volume_path    = "${local.volume_host}/arr"
  data_path      = local.data_host
  downloads_path = "${local.data_host}/torrents"
  networks       = [module.media_docker_network.name]
  proxy_networks = [module.homelab_docker_network.name]
  # If qBittorrent shares Gluetun's network namespace, arr should reach it via 'gluetun'
  qbittorrent_host = "gluetun"
}
```

The service definition is exported by the `services` module as `module.services.service_definitions` and consumed by networking modules in the root `main.tf`.
