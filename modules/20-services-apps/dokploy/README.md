# Dokploy (App Deployment)

This module deploys a Dokploy stack (Dokploy + Postgres + Redis) and a Traefik instance that Dokploy uses to route to Dokploy-managed applications.

In this repository, external traffic is handled by:

- `cloudflared` for explicitly configured subdomains (from `service_definitions`).
- `caddy-proxy` for reverse proxy + on-demand TLS. Caddy has an **on-demand TLS catch-all** which forwards to Dokploy's Traefik for domains managed inside Dokploy.

## What gets deployed

- **Dokploy app**: `dokploy/dokploy` (UI/API)
- **Postgres**: stores Dokploy state
- **Redis**: queue/cache
- **Traefik**: routes to Dokploy-managed apps (Swarm provider + file provider)
- **Docker network**: `dokploy-network` (overlay, attachable)

## Networking model

- Dokploy and Traefik are attached to:
  - `dokploy-network` (overlay) for Dokploy-managed services
  - `homelab-network` (bridge) via `var.networks` so Caddy/Cloudflared can reach them

- Traefik runs **internally only** (no host ports published). Ingress is via Caddy (and/or Cloudflared depending on your `service_definitions`).

## Traefik providers (how routing is discovered)

Traefik is configured with:

- **Swarm provider** (`providers.swarm`): discovers Dokploy-deployed services (Swarm services) on `dokploy-network`.
- **File provider** (`providers.file`): reads dynamic config files from:
  - Container path: `/etc/dokploy/traefik/dynamic`
  - Host path: `${var.volume_path}/config/traefik/dynamic`

Dokploy writes its generated dynamic configuration under `/etc/dokploy/...` inside the Dokploy container, which maps to the same host directory mounted into the Traefik container.

## How traffic flows (end-to-end)

### 1) Dokploy UI (`deploy.<domain>`)

- This module outputs a `service_definition` for the Dokploy UI.
- It’s typically published via Cloudflare Tunnel (see root `main.tf` / `cloudflared-tunnel` module).

### 2) Dokploy-managed app domains (on-demand TLS)

- Caddy has a catch-all site block (`https://`) with `tls { on_demand }`.
- For a new domain, Caddy calls the ask endpoint (`caddy-ask`) to decide whether certificate issuance is allowed.
- If allowed, Caddy obtains a Let's Encrypt certificate and then forwards the request to Traefik:
  - `reverse_proxy http://dokploy-traefik:80`

### 3) Allowing domains (required for on-demand TLS)

You must add any Dokploy-managed domain you want to use to:

- `${volume_path}/caddy/allowed-domains.txt` (one domain per line)

If the domain is not in the allowlist, Caddy will refuse issuance (fail-closed).

## Configuration

This module reads secrets from a local file:

- `modules/20-services-apps/dokploy/.env`

Start from the template:

- `modules/20-services-apps/dokploy/.env.example`

Required keys:

- `DOKPLOY_POSTGRES_PASSWORD`
- `DOKPLOY_ADVERTISE_ADDR` (your Docker host LAN IP)

## Common troubleshooting

- **Dokploy “DNS validation” shows `ENOTFOUND` but domain works**:
  - This is often a validation UX issue. Verify with actual resolution and/or an HTTPS request.

- **Caddy TLS handshake fails for a new Dokploy domain**:
  - Ensure the domain is present in `allowed-domains.txt`.
  - Verify `caddy-ask` returns `200` for that domain.

- **Traefik routes return 404**:
  - Check Traefik is using the Swarm provider and the correct network (`dokploy-network`).
  - Confirm dynamic config is being written to `${var.volume_path}/config/traefik/dynamic`.
