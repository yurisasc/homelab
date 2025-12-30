# My OpenTofu Homelab Infrastructure

![Homelab Architecture Diagram](docs/images/diagram.png)

This project uses [OpenTofu](https://opentofu.org/) to manage the infrastructure for my personal homelab. It's designed to be modular and focused on deploying Dockerized applications on a Debian server.

> 📖 **Background Story:** For a detailed explanation of how this proect came to be, see [My Homelab Was a Mess. Here's How I Fixed It with Code](https://yuris.dev/blog/homelab-opentofu).

## Table of Contents

1.  [Overview](#overview)
2.  [Prerequisites](#prerequisites)
3.  [Project Structure](#project-structure)
4.  [Configuration](#configuration)
5.  [Usage](#usage)
6.  [Services](#services)
7.  [Module Overview](#module-overview)
8.  [Future Plans](#future-plans)

## Overview

This OpenTofu configuration manages various self-hosted services primarily as Docker containers. The goals are:

* **Reproducibility:** Easily set up or replicate the homelab environment.
* **Version Control:** Track all infrastructure changes using Git.
* **Automation:** Automate the provisioning and management of services.
* **Modularity:** Organize infrastructure into reusable and understandable components.

## Prerequisites

Before you begin, ensure you have the following installed and configured:

* **OpenTofu:** Version `1.6.0` or higher. [Installation Guide](https://opentofu.org/docs/intro/install/)
* **Git:** For version control.
* **Docker:** Installed and running on the target host(s).
* **(Optional) Cloudflare Account:** If using the Cloudflare provider for DNS management or Tunnels. You'll need your Zone ID and an API Token.
* **(Optional) Tailscale:** For secure remote access.

## Project Structure

The project is organized as follows:

```
homelab/
├── .gitignore                # Files and directories to ignore
├── README.md                 # This file
│
├── main.tf                   # Root module: orchestrates module calls
├── variables.tf              # Root module: global input variables
├── outputs.tf                # Root module: global outputs
├── providers.tf              # Root module: provider configurations
├── versions.tf               # Root module: OpenTofu & provider version constraints
├── terraform.tfvars.example  # Example variables file
│
├── modules/                  # Local modules for different components
    ├── 00-globals/           # Optional: Global data sources/locals
    ├── 01-networking/
    │   ├── docker-network/
    │   ├── cloudflare-dns-record/
    │   └── cloudflared-tunnel/
    ├── 10-services-generic/
    │   └── docker-service/   # Generic module for deploying Docker containers
    └── 20-services-apps/     # Application-specific wrapper modules
        ├── jellyfin/
        ├── affine/
        └── ...               # Other application modules
│
└── services/                 # Application services (Docker containers)
```

## Configuration

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/yurisasc/homelab.git
    cd homelab
    ```

2.  **Provider Configuration:**
    Review `providers.tf` and ensure provider configurations are suitable. For providers requiring authentication (like Cloudflare), API tokens and other sensitive data should be supplied via variables.

3.  **Create a `.env` file:**
    Copy `.env.example` to `.env`:
    ```bash
    cp .env.example .env
    ```
    **Edit `.env` to set your specific values.** This file is included in `.gitignore` by default as it's expected to contain secrets.

## Usage

Make sure you are in the root directory of the project (`homelab/`).

1.  **Initialize OpenTofu:**
    This downloads the necessary provider plugins. Run this once when you first set up the project or when you add/change providers or modules.
    ```bash
    tofu init
    ```

2.  **Plan Changes:**
    This command shows you what OpenTofu will do to reach the desired state defined in your configuration files. Review the plan carefully.
    ```bash
    tofu plan
    ```

3.  **Apply Changes:**
    This command applies the changes outlined in the plan. You will be prompted for confirmation.
    ```bash
    tofu apply
    ```

4.  **View Outputs:**
    If you have defined outputs in `outputs.tf` or in your modules, you can view them:
    ```bash
    tofu output
    ```

5.  **Destroy Infrastructure (Use with Extreme Caution!):**
    This command will attempt to destroy all resources managed by this OpenTofu configuration.
    ```bash
    tofu destroy
    ```

## Services

| Service | Purpose | Published via | Reason |
|---|---|---|---|
| `actualbudget` | Personal budgeting | Cloudflare Tunnel | Public access without opening inbound ports |
| `affine-server` | Notes / knowledge base | Reverse proxy | Direct ingress control; avoids tunnel limitations |
| `jellyseerr` | Media request management | Reverse proxy | Direct ingress control; consistent with other reverse-proxied apps |
| `calibre-web-automated` | Calibre Web library UI | Reverse proxy | Direct ingress control |
| `copyparty` | File sharing / personal drive | Cloudflare Tunnel | Public access without opening inbound ports |
| `crawl4ai` | Crawling / automation service | Internal | Not published via ingress |
| `dify` | AI/LLM workflow platform | Cloudflare Tunnel | Public access without opening inbound ports |
| `dokploy` | App deployment dashboard | Cloudflare Tunnel | Admin UI reachable without opening inbound ports |
| `emulatorjs` | Retro game emulator UI | Internal | Not published via ingress |
| `fossflow` | Isometric diagramming tool | Cloudflare Tunnel | Public access without opening inbound ports |
| `glance` | RSS subscription | Cloudflare Tunnel | Public access without opening inbound ports |
| `immich-server` | Photo management | Reverse proxy | Better fit for large uploads/downloads; direct proxy tuning |
| `jellyfin` | Media streaming | Reverse proxy | Streaming/large transfers are not a good fit for Tunnel |
| `linkwarden` | Bookmark manager | Cloudflare Tunnel | Public access without opening inbound ports |
| `n8n` | Automation workflows | Cloudflare Tunnel | Public access without opening inbound ports |
| `n8n-mcp` | n8n MCP endpoint | Cloudflare Tunnel | Public access without opening inbound ports |
| `nocodb` | Airtable-like database UI | Cloudflare Tunnel | Public access without opening inbound ports |
| `ntfy` | Notifications | Cloudflare Tunnel | Public access without opening inbound ports |
| `portainer` | Docker management UI | Internal | Not published via ingress |
| `pterodactyl-wings` | Game server agent | Cloudflare Tunnel | Public access without opening inbound ports |
| `pterodactyl-panel` | Game server panel | Cloudflare Tunnel | Public access without opening inbound ports |
| `qbittorrent` | Torrent client UI | Internal | Not published via ingress; routed through VPN |
| `sabnzbd` | Usenet client | Cloudflare Tunnel | Public access without opening inbound ports |
| `searxng` | Metasearch engine | Cloudflare Tunnel | Public access without opening inbound ports |
| `cloudflared-homelab` | Cloudflare Tunnel ingress | Ingress | Publishes services via tunnel |
| `caddy-proxy` | Reverse proxy + TLS (including on-demand TLS) | Ingress | Publishes services via reverse proxy and handles Dokploy on-demand TLS |
| `caddy-ask` | On-demand TLS ask endpoint (allowlist) | Internal | Internal-only; called by Caddy during on-demand certificate issuance |
| `dokploy-traefik` | Internal routing for Dokploy-managed apps | Internal | Internal-only; receives traffic from Caddy and routes to Dokploy apps |

## Environment variables

This repo uses `.env` files for secrets / per-environment configuration.

- Root `.env`:
  - Start from `.env.example`.
  - Used by global modules/providers (e.g. Cloudflare credentials, TLS email) depending on your setup.

- Module `.env` files:
  - Some services require a module-level `.env` file.
  - Look for an `.env.example` in the relevant module folder and copy it to `.env` in the same directory.
  - Example: `modules/20-services-apps/dokploy/.env.example`

## Domain model

The current setup assumes a **single base domain** (e.g. `acme.com`) and publishes apps primarily as **subdomains** (one or more subdomains per service, e.g. `deploy.acme.com`, `glance.acme.com`, etc).

- Explicitly defined services generate a Caddy site block per subdomain.
- Dokploy-managed app domains are handled by Caddy's **on-demand TLS** catch-all and forwarded to Dokploy's internal Traefik.
- Some services can also be exposed via a Cloudflare Tunnel, which provides public ingress without directly opening inbound ports on your home network.

Multi-domain support is a likely future improvement. The main work would be:

- Extending the `service_definition` shape to support an explicit `domains` list (not just `subdomains`)
- Updating `caddy-proxy` and DNS automation to iterate over multiple domains

## Module Overview

This project aims for a high degree of modularity:

* **`modules/01-networking/`**: Contains modules for creating Docker networks, managing Cloudflare DNS records, deploying `cloudflared` tunnels, and running ingress services (e.g. Caddy).
* **`modules/10-services-generic/`**: A reusable module to deploy any generic module with common configurations (Docker container setup, etc.).
* **`modules/20-services-apps/`**: Contains "wrapper" modules for specific applications (e.g., Jellyfin, Affine, Nginx Proxy Manager). These modules typically call the generic `docker-service` module with pre-filled defaults and simpler inputs specific to that application.

Dokploy-specific notes live here:

- `modules/20-services-apps/dokploy/README.md`

Each module should have its own `README.md` (eventually) detailing its purpose, inputs, and outputs.

## Future Plans

1.  **Keep services codified:** Continue converting any remaining ad-hoc containers into OpenTofu modules.
2.  **Volume backups:** Add a backup solution for persisted volumes under `appdata/` (e.g. scheduled backups + retention + off-host storage).
