# n8n Module

This module deploys [n8n](https://n8n.io/), a workflow automation tool for technical people, as Docker containers in the homelab environment.

## Overview

The n8n module:

- Deploys two Docker containers:
  - `n8n`: The main workflow automation server
  - `n8n-postgres`: A PostgreSQL database backend
- Creates a dedicated Docker network (`n8n-network`) for container communication
- Persists data to volumes on the host
- Provides service definition for integration with networking modules

## Usage

```hcl
module "n8n" {
  source      = "./modules/20-services-apps/n8n"
  volume_path = "/path/to/volumes/n8n"
  networks    = ["homelab-network"]
}
```

## Variables

| Variable      | Description                                                | Type           | Default    |
| ------------- | ---------------------------------------------------------- | -------------- | ---------- |
| `image_tag`   | Tag of the n8n image to use                                | `string`       | `"latest"` |
| `volume_path` | Host path for n8n and Postgres data volumes                | `string`       | -          |
| `networks`    | List of additional networks to which n8n should be attached | `list(string)` | `[]`       |

## Outputs

| Output               | Description                                                |
| -------------------- | ---------------------------------------------------------- |
| `service_definition` | Service definition for integration with networking modules |

## Service Definition

This module outputs a service definition that is used by the networking modules to expose the service.

```hcl
{
  name         = "n8n"
  primary_port = 5678
  endpoint     = "http://n8n:5678"
  subdomains   = ["n8n"]
  publish_via  = "tunnel"  # Only publish through Cloudflare tunnel
}
```

## Environment Variables

n8n requires several environment variables to function properly. These are stored in a `.env` file in the module directory and read using the `dotenv` Terraform provider:

- Database configuration:
  - `POSTGRES_USER`: Root PostgreSQL user
  - `POSTGRES_PASSWORD`: Root PostgreSQL password
  - `POSTGRES_DB`: Database name for n8n
  - `POSTGRES_NON_ROOT_USER`: Non-root user for n8n to connect with
  - `POSTGRES_NON_ROOT_PASSWORD`: Password for the non-root user

- n8n configuration:
  - `N8N_HOST`: Host for n8n to use
  - `N8N_PORT`: Port for n8n to use
  - `N8N_PROTOCOL`: Protocol for n8n (http or https)
  - `WEBHOOK_URL`: URL for webhooks
  - `NODE_FUNCTION_ALLOW_EXTERNAL`: Whether to allow external function calls

## Data Persistence

n8n stores its data in two main volumes:

1. n8n application data: `/home/node/.n8n` in the container, mapped to `${volume_path}/n8n_storage/_data` on the host
2. PostgreSQL data: `/var/lib/postgresql/data` in the container, mapped to `${volume_path}/db_storage/_data` on the host

Additionally, an initialization script is mounted to the PostgreSQL container:
- `/docker-entrypoint-initdb.d/init-data.sh` in the container, from `${volume_path}/init-data.sh` on the host

## Networking

The module creates a dedicated Docker network named `n8n-network` for communication between the n8n and PostgreSQL containers. The n8n container is also attached to any additional networks specified in the `networks` variable, allowing it to communicate with other services in the homelab.

## Integration with Networking Modules

This service is configured to be exposed through a Cloudflare tunnel for secure remote access, set by `publish_via = "tunnel"`.

## Example Integration in Main Configuration

```hcl
module "n8n" {
  source      = "./modules/20-services-apps/n8n"
  volume_path = module.system_globals.volume_host
  networks    = [module.services.homelab_docker_network_name]
}

# The service definition is automatically included in the services output
module "services" {
  source = "./modules/services"
  # ...
  service_definitions = [
    module.n8n.service_definition,
    # Other service definitions
  ]
}
```
