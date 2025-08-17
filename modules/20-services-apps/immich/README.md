# Immich Module

This module deploys [Immich](https://immich.app/), a high-performance self-hosted photo and video backup solution, as Docker containers in the homelab environment.

## Overview

The Immich module:

- Deploys four Docker containers:
  - `immich-server`: The main Immich API/UI server (port 2283)
  - `immich-machine-learning`: The ML service for search, faces, and embeddings
  - `immich-postgres`: Immich-tuned PostgreSQL database
  - `immich-redis`: Valkey/Redis-compatible cache
- Creates a dedicated Docker network (`immich-network`) for inter-container communication
- Persists data to volumes on the host
- Provides a service definition for integration with networking modules

## Usage

```hcl
module "immich" {
  source       = "./modules/20-services-apps/immich"
  appdata_path = "/path/to/appdata/immich"
  library_path = "/path/to/data/media/photos"
  networks     = ["homelab-network"]
}
```

## Variables

| Variable        | Description                                                                      | Type           | Default    |
| --------------- | -------------------------------------------------------------------------------- | -------------- | ---------- |
| `image_tag`     | Tag of the Immich images to use (`server` and `machine-learning`)                | `string`       | `"release"` |
| `appdata_path`  | Base host path for Immich app data (e.g., PostgreSQL data and internal configs) | `string`       | -          |
| `library_path`  | Base host path for user library data and ML cache                                | `string`       | -          |
| `networks`      | List of additional networks to which the server should attach                    | `list(string)` | `[]`       |

## Outputs

| Output               | Description                                                |
| -------------------- | ---------------------------------------------------------- |
| `service_definition` | Service definition for integration with networking modules |

## Service Definition

This module outputs a service definition used by networking modules to expose the service.

```hcl
{
  name         = "immich-server"
  primary_port = 2283
  endpoint     = "http://immich-server:2283"
  subdomains   = ["photos"]
  publish_via  = "reverse_proxy"
}
```

## Environment Variables

Only the database credentials are expected in a `.env` file in this module directory and are read using the `dotenv` Terraform provider. Everything else is configured directly in Terraform.

Required in `modules/20-services-apps/immich/.env`:

- `DB_USERNAME`: PostgreSQL user
- `DB_PASSWORD`: PostgreSQL password
- `DB_DATABASE_NAME`: Database name

A ready-to-copy `modules/20-services-apps/immich/.env.example` is provided.

## Data Persistence

Immich stores data in the following volumes:

1. Library storage: `/data` in `immich-server`, mapped to `${library_path}/library` on the host
2. ML model cache: `/cache` in `immich-machine-learning`, mapped to `${library_path}/machine-learning/cache` on the host
3. PostgreSQL data: `/var/lib/postgresql/data` in `immich-postgres`, mapped to `${appdata_path}/postgres/pgdata` on the host

## Networking

The module creates a dedicated Docker network named `immich-network` for communication between Immich components. The Immich server container is also attached to any additional networks specified in the `networks` variable, allowing it to communicate with other services in the homelab.

## Dependencies

- `immich-server` depends on `immich-postgres` and `immich-redis`
- `immich-postgres` and `immich-redis` include healthchecks
- The ML service is independent and discovered by the server internally; tuning can be done via the Immich admin UI

## Integration with Networking Modules

This service is configured to be exposed through the Caddy reverse proxy, set by `publish_via = "reverse_proxy"`.

## Example Integration in Main Configuration

```hcl
module "immich" {
  source       = "./modules/20-services-apps/immich"
  appdata_path = "${module.system_globals.volume_host}/appdata/immich"
  library_path = "${module.system_globals.volume_host}/data/media/photos"
  networks     = [module.services.homelab_docker_network_name]
}

# The service definition is automatically included in the services output
module "services" {
  source = "./modules/services"
  # ...
  service_definitions = [
    module.immich.service_definition,
    # Other service definitions
  ]
}
