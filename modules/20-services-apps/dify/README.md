# Dify Module

This module deploys [Dify](https://dify.ai/), an open-source LLM app development platform, as a collection of Docker containers in the homelab environment.

## Overview

The Dify module:

- Deploys a comprehensive LLM orchestration stack including:
  - `dify-api`: Core API service
  - `dify-worker` & `dify-worker-beat`: Celery workers for background tasks
  - `dify-web`: Frontend interface
  - `dify-postgres`: Database backend
  - `dify-redis`: Cache and message broker
  - `dify-weaviate`: Vector database for RRD/Knowledge
  - `dify-sandbox`: Isolated environment for code execution
  - `dify-ssrf-proxy`: Security proxy for external requests
  - `dify-plugin-daemon`: Plugin management service
  - `dify-nginx`: Internal gateway routing traffic between components
- Persists all application data, databases, and vector indices to host volumes
- Provides automated database backup configuration
- Integrates with system-wide SMTP and Cloudflare settings

## Usage

```hcl
module "dify" {
  source          = "./modules/20-services-apps/dify"
  volume_path     = "/path/to/volumes/dify"
  networks        = ["homelab-network"]
  backup_networks = ["backup-network"]
  image_tag       = "1.11.2"
}
```

## Variables

| Variable          | Description                                                | Type           | Default    |
| ----------------- | ---------------------------------------------------------- | -------------- | ---------- |
| `image_tag`       | Tag for the Dify application images                        | `string`       | `"1.11.2"` |
| `volume_path`     | Host path for all Dify service volumes                     | `string`       | -          |
| `networks`        | Public-facing networks for the Nginx ingress               | `list(string)` | `[]`       |
| `backup_networks` | Networks used for database backup access                   | `list(string)` | `[]`       |
| `subdomain`       | Subdomain for the Dify service                             | `string`       | `"dify"`   |

## Outputs

| Output               | Description                                                |
| -------------------- | ---------------------------------------------------------- |
| `service_definition` | Service definition for integration with networking modules |
| `db_backup_config`   | Configuration for automated database backups               |

## Service Definition

This module outputs a service definition that is used by the networking modules to expose the service via the internal Nginx gateway.

```hcl
{
  name         = "dify-nginx"
  primary_port = 80
  endpoint     = "http://dify-nginx:80"
  subdomains   = ["dify"]
  publish_via  = "tunnel"
}
```

## Data Persistence

Dify manages persistence across several specialized volumes under the provided `volume_path`:

- **Storage**: App uploads and generated files (`/storage`)
- **Database**: PostgreSQL data (`/db/data`)
- **Cache**: Redis data (`/redis/data`)
- **Knowledge**: Weaviate vector indices (`/weaviate`)
- **Sandbox**: Code execution dependencies (`/sandbox/dependencies`)
- **Plugins**: Plugin storage (`/plugin_daemon`)

## Architecture & Networking

Dify uses two internal Docker networks created by the module:
1. `dify-network`: Connects all core components.
2. `dify-ssrf-network`: Isolates the Sandbox and API from the SSRF Proxy for secure external data fetching.

## Integration with Networking Modules

The service is published via a Cloudflare Tunnel (`publish_via = "tunnel"`). All routing between the web frontend and API is handled internally by the `dify-nginx` container using a dynamically generated configuration.

## Example Integration in Main Configuration

```hcl
module "dify" {
  source          = "./modules/20-services-apps/dify"
  volume_path     = "${local.volume_host}/dify"
  networks        = [module.homelab_docker_network.name]
  backup_networks = [module.backup_docker_network.name]
  image_tag       = "1.11.2"
}

# The service definition is automatically included in the services output
module "services" {
  source = "./modules/services"
  # ...
  service_definitions = [
    module.dify.service_definition,
    # Other service definitions
  ]
}
```
