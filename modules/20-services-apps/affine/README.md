# AFFiNE Module

This module deploys [AFFiNE](https://affine.pro/), a privacy-first, local-first, note-taking and knowledge base application, as Docker containers in the homelab environment.

## Overview

The AFFiNE module:

- Deploys four Docker containers:
  - `affine_server`: The main AFFiNE application server
  - `affine_migration_job`: A container that runs pre-deployment migrations
  - `affine_postgres`: A PostgreSQL (pgvector) database backend
  - `affine_redis`: A Redis instance for caching and temporary data
- Creates a dedicated Docker network (`affine-network`) for container communication
- Persists data to volumes on the host
- Provides service definition for integration with networking modules

## Usage

```hcl
module "affine" {
  source      = "./modules/20-services-apps/affine"
  volume_path = "/path/to/volumes/affine"
  networks    = ["homelab-network"]
}
```

## Variables

| Variable      | Description                                                    | Type           | Default    |
| ------------- | -------------------------------------------------------------- | -------------- | ---------- |
| `image_tag`   | Tag of the AFFiNE image to use                                 | `string`       | `"stable"` |
| `volume_path` | Host path for AFFiNE and database data volumes                 | `string`       | -          |
| `networks`    | List of additional networks to which AFFiNE should be attached | `list(string)` | `[]`       |

## Outputs

| Output               | Description                                                |
| -------------------- | ---------------------------------------------------------- |
| `service_definition` | Service definition for integration with networking modules |

## Service Definition

This module outputs a service definition that is used by the networking modules to expose the service.

```hcl
{
  name         = "affine_server"
  primary_port = 3010
  endpoint     = "http://affine_server:3010"
  subdomains   = ["affine"]
  publish_via  = "tunnel"  # Only publish through Cloudflare tunnel
}
```

## Environment Variables

AFFiNE requires several environment variables to function properly. These are stored in a `.env` file in the module directory and read using the `dotenv` Terraform provider:

- Database configuration:

  - `DB_USERNAME`: PostgreSQL user
  - `DB_PASSWORD`: PostgreSQL password
  - `DB_DATABASE`: Database name (defaults to "affine")

- AFFiNE configuration:

  - `AFFINE_REVISION`: Version of AFFiNE to use ("stable" or "canary") (defaults to "canary")
  - `PORT`: External port for the AFFiNE server (defaults to 3010)
  - `AFFINE_SERVER_HTTPS`: Whether to use HTTPS (defaults to "true")
  - `AFFINE_SERVER_HOST`: Hostname for the AFFiNE server
  - `AFFINE_SERVER_NAME`: Name for the AFFiNE server (defaults to "AFFiNE Selfhosted")

- Cloudflare R2 configuration:
  - `R2_OBJECT_STORAGE_ACCOUNT_ID`: Cloudflare R2 account ID
  - `R2_OBJECT_STORAGE_ACCESS_KEY_ID`: Cloudflare R2 access key ID
  - `R2_OBJECT_STORAGE_SECRET_ACCESS_KEY`: Cloudflare R2 secret access key

## Data Persistence

AFFiNE stores its data in three main volumes:

1. AFFiNE application data: `/root/.affine/storage` in the container, mapped to `${volume_path}/self-host/storage` on the host
2. AFFiNE configuration: `/root/.affine/config` in the container, mapped to `${volume_path}/self-host/config` on the host
3. PostgreSQL data: `/var/lib/postgresql/data` in the container, mapped to `${volume_path}/self-host/postgres/pgdata` on the host

## Networking

The module creates a dedicated Docker network named `affine-network` for communication between the AFFiNE components. The AFFiNE server container is also attached to any additional networks specified in the `networks` variable, allowing it to communicate with other services in the homelab.

## Dependencies

The AFFiNE containers have the following dependencies:

- The main `affine_server` depends on PostgreSQL, Redis, and the migration job
- The migration job depends on PostgreSQL and Redis
- Both PostgreSQL and Redis use healthchecks to ensure they're ready before dependent services start

## Integration with Networking Modules

This service is configured to be exposed through the Caddy reverse proxy, set by `publish_via = "reverse_proxy"`.

## Example Integration in Main Configuration

```hcl
module "affine" {
  source      = "./modules/20-services-apps/affine"
  volume_path = module.system_globals.volume_host
  networks    = [module.services.homelab_docker_network_name]
}

# The service definition is automatically included in the services output
module "services" {
  source = "./modules/services"
  # ...
  service_definitions = [
    module.affine.service_definition,
    # Other service definitions
  ]
}
```
