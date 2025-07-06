# n8n Module

This module deploys [n8n](https://n8n.io/), a workflow automation tool, along with its dependencies and the [n8n-mcp](https://github.com/czlonkowski/n8n-mcp) community node manager, as Docker containers in the homelab environment.

## Overview

The n8n module:

- Deploys four Docker containers:
  - `n8n`: The main workflow automation server
  - `n8n-postgres`: A PostgreSQL database backend
  - `n8n-redis`: A Redis instance for queuing
  - `n8n-mcp`: A community node management tool for n8n
- Creates a dedicated Docker network (`n8n-network`) for container communication
- Persists data to volumes on the host
- Provides service definitions for integration with networking modules

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
| `volume_path` | Host path for n8n, Postgres, Redis, and n8n-mcp data volumes | `string`       | -          |
| `networks`    | List of additional networks to which n8n should be attached | `list(string)` | `[]`       |

## Outputs

| Output                       | Description                                                |
| ---------------------------- | ---------------------------------------------------------- |
| `service_definition`         | Service definition for the n8n container                   |
| `n8n_mcp_service_definition` | Service definition for the n8n-mcp container               |

## Service Definitions

This module outputs two service definitions that are used by the networking modules to expose the services.

### n8n

```hcl
{
  name         = "n8n"
  primary_port = 5678
  endpoint     = "http://n8n:5678"
  subdomains   = ["n8n"]
  publish_via  = "tunnel"
}
```

### n8n-mcp

```hcl
{
  name         = "n8n-mcp"
  primary_port = 3000
  endpoint     = "http://n8n-mcp:3000"
  subdomains   = ["n8n-mcp"]
  publish_via  = "tunnel"
}
```

## Environment Variables

The services require several environment variables to function properly. These are stored in a `.env` file in the module directory and read using the `dotenv` Terraform provider:

- **Database configuration (`n8n-postgres`)**:
  - `POSTGRES_USER`: Root PostgreSQL user
  - `POSTGRES_PASSWORD`: Root PostgreSQL password
  - `POSTGRES_DB`: Database name for n8n
  - `POSTGRES_NON_ROOT_USER`: Non-root user for n8n to connect with
  - `POSTGRES_NON_ROOT_PASSWORD`: Password for the non-root user

- **n8n configuration (`n8n`)**:
  - `N8N_HOST`: Host for n8n to use
  - `N8N_PORT`: Port for n8n to use
  - `N8N_PROTOCOL`: Protocol for n8n (http or https)
  - `WEBHOOK_URL`: URL for webhooks
  - `NODE_FUNCTION_ALLOW_EXTERNAL`: Whether to allow external function calls

- **n8n-mcp configuration (`n8n-mcp`)**:
  - `N8N_MCP_AUTH_TOKEN`: Authentication token for n8n-mcp.
  - `N8N_API_KEY`: n8n API key for n8n-mcp to interact with the n8n instance.

## Data Persistence

The services store data in several volumes:

1.  **n8n application data**: `/home/node/.n8n` in the container, mapped to `${volume_path}/n8n_storage/_data` on the host
2.  **PostgreSQL data**: `/var/lib/postgresql/data` in the container, mapped to `${volume_path}/db_storage/_data` on the host
3.  **Redis data**: `/data` in the container, mapped to `${volume_path}/redis_data` on the host
4.  **n8n-mcp data**: `/app/data` in the container, mapped to `${volume_path}/n8n_mcp_storage/_data` on the host

Additionally, an initialization script is mounted to the PostgreSQL container:
- `/docker-entrypoint-initdb.d/init-data.sh` in the container, from `${volume_path}/init-data.sh` on the host

## Networking

The module creates a dedicated Docker network named `n8n-network` for communication between all containers. The `n8n` and `n8n-mcp` containers are also attached to any additional networks specified in the `networks` variable, allowing them to communicate with other services in the homelab.

## Integration with Networking Modules

The services are configured to be exposed through a Cloudflare tunnel for secure remote access, set by `publish_via = "tunnel"`.

## Example Integration in Main Configuration

```hcl
module "n8n" {
  source      = "./modules/20-services-apps/n8n"
  volume_path = module.system_globals.volume_host
  networks    = [module.services.homelab_docker_network_name]
}

# The service definitions are automatically included in the services output
module "services" {
  source = "./modules/services"
  # ...
  service_definitions = [
    module.n8n.service_definition,
    module.n8n.n8n_mcp_service_definition,
    # Other service definitions
  ]
}
```

## Using n8n-mcp with your IDE

To connect your IDE to the `n8n-mcp` server, you can use the following configuration in your IDE's settings. This allows the IDE to use the n8n instance as a tool provider.

Make sure to replace `<domain>` with your actual domain and populate the `AUTH_TOKEN` with the value of `N8N_MCP_AUTH_TOKEN` from your `.env` file.

```json
{
  "mcpServers": {
    "n8n-mcp": {
      "command": "npx",
      "args": [
        "mcp-remote",
        "https://n8n-mcp.<domain>/mcp",
        "--header",
        "Authorization: Bearer ${AUTH_TOKEN}",
        "--transport",
        "http-only"
      ],
      "env": {
        "AUTH_TOKEN": "..."
      }
    }
  }
}
```
