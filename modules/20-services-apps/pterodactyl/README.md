# Pterodactyl Module

This module is a parent module for deploying the [Pterodactyl](https://pterodactyl.io/) game server management system, which consists of multiple components:

1. **Panel** - The web-based administration interface and API server
2. **Wings** - The game server agent that controls individual game servers

## Overview

The Pterodactyl module consists of two submodules:

- `panel` - Deploys the Pterodactyl control panel with its database and cache servers
- `wings` - Deploys the Pterodactyl Wings agent for running game servers

For a complete installation, both components should be deployed.

## Architecture

Pterodactyl is designed with a client-server architecture:

- **Panel (Server)**: The central management interface where administrators create servers, manage users, and configure settings.
- **Wings (Agent)**: Installed on each machine that will run game servers, communicates with the Panel via API.

In a homelab environment, you might deploy both components on the same machine or separate them for better resource allocation.

## Usage

### Deploying Both Components

```hcl
module "pterodactyl_panel" {
  source      = "./modules/20-services-apps/pterodactyl/panel"
  volume_path = "${var.volume_host}/pterodactyl/panel"
  networks    = [module.services.homelab_docker_network_name]
}

module "pterodactyl_wings" {
  source      = "./modules/20-services-apps/pterodactyl/wings"
  volume_path = "${var.volume_host}/pterodactyl/wings"
  networks    = [module.services.homelab_docker_network_name]
}

# Include both service definitions in your networking modules
module "services" {
  source = "./modules/services"
  # ...
  service_definitions = [
    module.pterodactyl_panel.service_definition,
    module.pterodactyl_wings.service_definition,
    # Other service definitions
  ]
}
```

## Configuration Requirements

### Panel Setup

1. Create a `.env` file in the panel module directory with required variables:
   - Database credentials (`MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD`, etc.)
   - App settings (`APP_URL`, `APP_TIMEZONE`, etc.)
   - CORS and proxy settings
   
2. SMTP settings are sourced from the global SMTP module

### Wings Setup

1. After deploying the Panel, you need to:
   - Create a node in the Panel UI
   - Download the wings configuration from the Panel
   - Place it at `${volume_path}/etc/config.yml` for the Wings module

## Network Configuration

Both components create their own dedicated Docker networks:

- `ptero-panel`: For communication between Panel, database, and cache
- `ptero-wings`: For communication between Wings and game servers

Additionally, both components need to be connected to your main homelab network to communicate with each other.

## Service Definitions

Both components generate service definitions that can be used by your networking modules:

- Panel: Published on the domain `gameservers.yourdomain.com`
- Wings: Published on the domain `wings.yourdomain.com`

## Security Considerations

- Wings requires `privileged` mode to create game server containers
- Panel communicates with Wings via API using a token configured in the wings config.yml

## Additional Documentation

For more detailed information about each component, please see:

- [Panel README](/modules/20-services-apps/pterodactyl/panel/README.md)
- [Wings README](/modules/20-services-apps/pterodactyl/wings/README.md)

For official Pterodactyl documentation, visit [https://pterodactyl.io/](https://pterodactyl.io/)
