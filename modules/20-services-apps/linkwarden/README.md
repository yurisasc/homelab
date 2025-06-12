# Linkwarden Module

This module deploys [Linkwarden](https://linkwarden.app/), a self-hosted bookmark manager and link archive, as Docker containers in the homelab environment.

## Overview

The Linkwarden module:

- Deploys two Docker containers:
  - `linkwarden`: The main application server (Next.js)
  - `postgres`: A PostgreSQL database backend
- Persists data to volumes on the host
- Provides service definition for integration with networking modules

## Usage

```hcl
module "linkwarden" {
  source      = "./modules/20-services-apps/linkwarden"
  volume_path = "/path/to/volumes/linkwarden"
  networks    = ["homelab-network"]
}
```

## Variables

| Variable      | Description                                                | Type           | Default    |
| ------------- | ---------------------------------------------------------- | -------------- | ---------- |
| `image_tag`   | Tag of the Linkwarden image to use                         | `string`       | `"latest"` |
| `volume_path` | Host path for Linkwarden and Postgres data volumes         | `string`       | -          |
| `networks`    | List of networks to which containers should be attached    | `list(string)` | -          |

## Outputs

| Output               | Description                                                |
| -------------------- | ---------------------------------------------------------- |
| `service_definition` | Service definition for integration with networking modules |

## Service Definition

This module outputs a service definition that is used by the networking modules to expose the service.

```hcl
{
  name         = "linkwarden"
  primary_port = 3000
  endpoint     = "http://linkwarden:3000"
  subdomains   = ["links"]
  publish_via  = "tunnel"  # Only publish through Cloudflare tunnel
}
```

## Environment Variables

Linkwarden requires several environment variables to function properly. These are stored in a `.env` file in the module directory and read using the `dotenv` Terraform provider:

- `NEXTAUTH_SECRET`: A secret key for NextAuth.js
- `NEXTAUTH_URL`: The public URL where Linkwarden will be accessed
- `POSTGRES_PASSWORD`: Password for the PostgreSQL database

## Data Persistence

Linkwarden stores its data in two volumes:

1. Linkwarden data: `/data/data` in the container, mapped to `${volume_path}/data` on the host
2. PostgreSQL data: `/var/lib/postgresql/data` in the container, mapped to `${volume_path}/pgdata` on the host

## Integration with Networking Modules

This service is configured to be exposed through a Cloudflare tunnel for secure remote access, set by `publish_via = "tunnel"`.

## Example Integration in Main Configuration

```hcl
module "linkwarden" {
  source      = "./modules/20-services-apps/linkwarden"
  volume_path = module.system_globals.volume_host
  networks    = [module.services.homelab_docker_network_name]
}

# The service definition is automatically included in the services output
module "services" {
  source = "./modules/services"
  # ...
  service_definitions = [
    module.linkwarden.service_definition,
    # Other service definitions
  ]
}
```
