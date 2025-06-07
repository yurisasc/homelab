# My OpenTofu Homelab Infrastructure

This project uses [OpenTofu](https://opentofu.org/) to manage the infrastructure for my personal homelab. It's designed to be modular and evolve, initially focusing on deploying Dockerized applications on a Debian server ("casa") and later expanding to include Proxmox VE for virtualization.

**Current Time:** June 5, 2025

## Table of Contents

1.  [Overview](#overview)
2.  [Prerequisites](#prerequisites)
3.  [Project Structure](#project-structure)
4.  [Configuration](#configuration)
5.  [Usage](#usage)
6.  [Module Overview](#module-overview)
7.  [Future Plans](#future-plans)

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
* **Docker:** Installed and running on the target host(s) (initially "casa", later on VMs within Proxmox).
* **(Optional) Cloudflare Account:** If using the Cloudflare provider for DNS management or Tunnels. You'll need your Zone ID and an API Token.
* **(Future) Proxmox VE:** When moving to the virtualization phase, a Proxmox VE host will be required.
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
    ├── 02-compute/           # Future: Proxmox VM/LXC modules
    │   └── proxmox-vm/
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
    Review `providers.tf` and ensure provider configurations are suitable. For providers requiring authentication (like Cloudflare or Proxmox later), API tokens and other sensitive data should be supplied via variables.

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

## Module Overview

This project aims for a high degree of modularity:

* **`modules/01-networking/`**: Contains modules for creating Docker networks, managing Cloudflare DNS records, and deploying `cloudflared` tunnels.
* **`modules/10-services-generic/`**: A reusable module to deploy any generic module with common configurations (Docker container setup, etc.).
* **`modules/20-services-apps/`**: Contains "wrapper" modules for specific applications (e.g., Jellyfin, Affine, Nginx Proxy Manager). These modules typically call the generic `docker-service` module with pre-filled defaults and simpler inputs specific to that application.
* **`modules/02-compute/`**: (Planned for future Proxmox integration) Will contain modules for provisioning Virtual Machines or LXC containers on Proxmox VE, which can then serve as hosts for Docker or other services.

Each module should have its own `README.md` (eventually) detailing its purpose, inputs, and outputs.

## Future Plans

1.  **Phase 1 (Current):** Codify all existing Dockerized services running on the primary Debian server ("casa") using OpenTofu.
2.  **Phase 2:** Set up a new machine with Proxmox VE.
3.  **Phase 3:** Adapt and expand these OpenTofu configurations to:
    * Provision VMs on Proxmox (e.g., a dedicated Docker host VM).
    * Deploy the Dockerized services (from Phase 1) inside these VMs using OpenTofu.
    * Potentially manage LXC containers on Proxmox for suitable services.
