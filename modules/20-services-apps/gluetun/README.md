# Gluetun (Mullvad Wireguard)

This module runs Gluetun to provide a VPN network stack for other containers.
You can route qBittorrent through Gluetun by setting its `network_mode` to `container:gluetun` using the provided toggle in the qBittorrent module.

- Image: `qmcgaw/gluetun:v3.39.0`
- Requires: NET_ADMIN capability and `/dev/net/tun` device
- Default: No ports exposed on host. Publish only if you need host access.
- Attach Gluetun to the same Docker network as services that should reach apps running through it (e.g., `media-network`).

## Usage

Example in `services/main.tf`:

```hcl
module "gluetun" {
  source      = "${local.module_dir}/20-services-apps/gluetun"
  volume_path = "${local.volume_host}/gluetun"
  networks    = [module.media_docker_network.name]
  # Optionally expose qBittorrent's Web UI to the host via Gluetun:
  # ports = [{ internal = 8080, external = 8080, protocol = "tcp" }]
}

module "qbittorrent" {
  source                 = "${local.module_dir}/20-services-apps/qbittorrent"
  volume_path            = "${local.volume_host}/qbittorrent"
  downloads_path         = "${local.data_host}/torrents"
  networks               = [module.media_docker_network.name]
  connect_via_gluetun    = true
  gluetun_container_name = "gluetun"
}

module "arr" {
  source           = "${local.module_dir}/20-services-apps/arr"
  volume_path      = "${local.volume_host}/arr"
  data_path        = local.data_host
  downloads_path   = "${local.data_host}/torrents"
  networks         = [module.media_docker_network.name]
  proxy_networks   = [module.homelab_docker_network.name]
  qbittorrent_host = "gluetun" # arr containers will reach qBt at http://gluetun:8080
}
```

## Environment variables

Place a `.env` file in this module directory (`modules/20-services-apps/gluetun/.env`). See `.env.example` for all options. Key variables:

- VPN_SERVICE_PROVIDER=mullvad
- VPN_TYPE=wireguard
- WIREGUARD_PRIVATE_KEY=... (required)
- WIREGUARD_ADDRESSES=10.64.0.2/32 (example)
- SERVER_CITIES=... or SERVER_COUNTRIES=...
- SERVER_HOSTNAMES=id-jpu-wg-001 (optional exact server pin; supports comma-separated list)
- UPDATER_PERIOD=24h (optional)
- FIREWALL_OUTBOUND_SUBNETS=10.0.0.0/8,192.168.0.0/16 (optional; allow containers to reach LAN subnets)
- Optional: `FIREWALL_INPUT_PORTS=8080` if you need other containers/LAN to initiate connections to services through Gluetun.

Notes:
- When qBittorrent shares Gluetun's network, other containers should use `http://gluetun:8080`.
- To access qBittorrent UI from the host, publish `8080/tcp` on Gluetun via this module's `ports` input or set `FIREWALL_INPUT_PORTS` accordingly.
- Do not publish ports on qBittorrent when using Gluetun network mode; publish on Gluetun instead.

Pinning a specific server:
- Set `SERVER_HOSTNAMES=id-jpu-wg-001` to pin to Mullvad Jakarta `id-jpu-wg-001`.
- The module also accepts `SERVER_HOSTNAME` for compatibility (falls back to it if `SERVER_HOSTNAMES` is not set).
