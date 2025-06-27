# Media Server Module

This module deploys a complete media server stack using Docker containers in the homelab environment. It includes content management services (Sonarr, Radarr, Readarr), content discovery (Prowlarr, Jellyseerr), download clients (Qbittorrent, Sabnzbd), and media playback (Jellyfin).

## Overview

The Media Server module:

- Deploys multiple Docker containers:
  - `sonarr`: Series/TV management system
  - `radarr`: Movie management system
  - `readarr`: Book management system
  - `jellyseerr`: Content request and discovery system
  - `prowlarr`: Indexer management system
  - `qbittorrent`: Torrent download client with VueTorrent UI
  - `unpackerr`: Automatic extraction utility
  - `jellyfin`: Media server for streaming content
  - `sabnzbd`: Usenet download client
  - `flaresolverr`: Proxy service to bypass Cloudflare and other protection
  - `autoheal`: Service for automatic container health restarts
- Creates a dedicated Docker network (`media-server`) for container communication
- Persists data to volumes on the host
- Provides service definitions for integration with networking modules
- Exposes Jellyfin, Jellyseerr, and Sabnzbd via reverse proxy

## Usage

```hcl
module "media_server" {
  source        = "./modules/20-services-apps/media-server"
  volume_path   = "/path/to/app/data"
  data_root     = "/path/to/media/data"
  download_root = "/path/to/download/data"
  user_id       = "1000"
  group_id      = "1000"
  timezone      = "UTC"
  hostname      = "example.com"
  sonarr_api_key = "your-sonarr-api-key"
  radarr_api_key = "your-radarr-api-key"
  networks      = ["homelab-network"]
}
```

## Variables

| Variable         | Description                                       | Type           | Default  |
| ---------------- | ------------------------------------------------- | -------------- | -------- |
| `volume_path`    | Base directory for application data               | `string`       | -        |
| `data_root`      | Root directory for media data                     | `string`       | -        |
| `download_root`  | Directory for downloads                           | `string`       | -        |
| `user_id`        | User ID for container permissions                 | `string`       | `"1000"` |
| `group_id`       | Group ID for container permissions                | `string`       | `"1000"` |
| `timezone`       | Timezone for the containers                       | `string`       | `"UTC"`  |
| `hostname`       | Hostname for the Jellyfin PublishedServerUrl      | `string`       | -        |
| `sonarr_api_key` | API key for Sonarr                                | `string`       | -        |
| `radarr_api_key` | API key for Radarr                                | `string`       | -        |
| `networks`       | List of networks to which containers are attached | `list(string)` | `[]`     |

## Outputs

| Output                | Description                                                        |
| --------------------- | ------------------------------------------------------------------ |
| `service_definitions` | Service definitions for Jellyfin, Jellyseerr, and Sabnzbd services |
| `network_name`        | Name of the media server network                                   |

## Services

### Sonarr
TV series management tool that integrates with various download clients and indexers to automate obtaining TV episodes.
- Port: 8989
- Volumes:
  - Config: `/config` → `${volume_path}/sonarr`
  - Data: `/data` → `${data_root}`

### Radarr
Movie management tool that integrates with various download clients and indexers to automate obtaining movies.
- Port: 7878
- Volumes:
  - Config: `/config` → `${volume_path}/radarr`
  - Data: `/data` → `${data_root}`

### Readarr
Book management tool that integrates with various download clients and indexers to automate obtaining books.
- Port: 8787
- Volumes:
  - Config: `/config` → `${volume_path}/readarr`
  - Books: `/books` → `${data_root}`

### Jellyseerr
Media request system that integrates with Jellyfin to allow users to request new content.
- Port: 5055
- Volumes:
  - Config: `/app/config` → `${volume_path}/jellyseerr`

### Prowlarr
Indexer manager/proxy that integrates with various PVR apps and download clients.
- Port: 9696
- Volumes:
  - Config: `/config` → `${volume_path}/prowlarr`

### FlareSolverr
Proxy server to bypass Cloudflare and other protection methods.
- Port: 8191

### QBittorrent
Torrent client with VueTorrent web interface.
- Port: 8080
- Volumes:
  - Config: `/config` → `${volume_path}/qbittorrent`
  - Downloads: `/data/torrents` → `${download_root}`

### Unpackerr
Extracts completed downloads automatically for Sonarr, Radarr, and others.
- Volumes:
  - Downloads: `/data/torrents` → `${download_root}`

### Jellyfin
Media server for streaming content to various devices.
- Ports:
  - 8096 (HTTP)
  - 7359 (UDP)
  - 1900 (UDP)
- Volumes:
  - Config: `/config` → `${volume_path}/jellyfin`
  - Data: `/data` → `${data_root}`
- Devices:
  - `/dev/dri/` for hardware acceleration

### Sabnzbd
Usenet download client.
- Port: 6789 (external) → 8080 (internal)
- Volumes:
  - Config: `/config` → `${volume_path}/sabnzbd/config`
  - Downloads: `/downloads` → `${data_root}/usenet/downloads`

### Autoheal
Service that automatically checks for container health and restarts unhealthy containers.
- Requires access to Docker socket

## Networking

The module creates a dedicated Docker network named `media-server` for communication between the components. Each service container is also attached to any additional networks specified in the `networks` variable, allowing it to communicate with other services in the homelab.

## Reverse Proxy Integration

Three services are configured to be exposed through a reverse proxy:

- **Jellyfin**: Exposed at subdomain `jellyfin`
- **Jellyseerr**: Exposed at subdomain `requests`
- **Sabnzbd**: Exposed at subdomain `sabnzbd`

These services have their `publish_via` property set to `"reverse_proxy"` in their service definitions.

## Example Integration in Main Configuration

```hcl
module "media_server" {
  source         = "./modules/20-services-apps/media-server"
  volume_path    = module.system_globals.volume_host
  data_root      = "${module.system_globals.data_root}/media"
  download_root  = "${module.system_globals.data_root}/downloads"
  user_id        = module.system_globals.user_id
  group_id       = module.system_globals.group_id
  timezone       = module.system_globals.timezone
  hostname       = "example.com"
  sonarr_api_key = var.sonarr_api_key
  radarr_api_key = var.radarr_api_key
  networks       = [module.services.homelab_docker_network_name]
}

# The service definitions are automatically included in the services output
module "services" {
  source = "./modules/services"
  # ...
  service_definitions = concat(
    module.media_server.service_definitions,
    # Other service definitions
  )
}
```
