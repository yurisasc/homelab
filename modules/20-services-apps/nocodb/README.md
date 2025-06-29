# NocoDB Module

This module deploys [NocoDB](https://www.nocodb.com/), an open-source no-code database platform that transforms PostgreSQL into a smart spreadsheet interface, as Docker containers in the homelab environment.

## Overview

The NocoDB module:

- Deploys two Docker containers:
  - `nocodb`: The main NocoDB application server
  - `nocodb-postgres`: A PostgreSQL database backend
- Creates a dedicated Docker network (`nocodb-network`) for container communication
- Persists data to volumes on the host
- Provides service definition for integration with networking modules

## Usage

```hcl
module "nocodb" {
  source           = "./modules/20-services-apps/nocodb"
  volume_path      = "/path/to/volumes"
  networks         = ["homelab-network"]
  postgres_user    = "postgres"
  postgres_password = "your_secure_password"
  postgres_db      = "root_db"
}
```

## Variables

| Variable            | Description                                                    | Type           | Default                |
| ------------------- | -------------------------------------------------------------- | -------------- | ---------------------- |
| `image_tag`         | Tag of the NocoDB image to use                                 | `string`       | `"latest"`             |
| `postgres_image_tag`| Tag of the PostgreSQL image to use                             | `string`       | `"16.6"`               |
| `volume_path`       | Host path for NocoDB and database data volumes                 | `string`       | -                      |
| `networks`          | List of networks to which NocoDB should be attached            | `list(string)` | `[]`                   |

## Outputs

| Output               | Description                                                |
| -------------------- | ---------------------------------------------------------- |
| `service_definition` | Service definition for integration with networking modules |

## Service Definition

This module outputs a service definition that is used by the networking modules to expose the service.

```hcl
{
  name         = "nocodb"
  primary_port = 8080
  endpoint     = "http://nocodb:8080"
  subdomains   = ["nocodb"]
  publish_via  = "tunnel"  # Only publish through Cloudflare tunnel
}
```

## Environment Variables

NocoDB requires several environment variables to function properly. These are stored in a `.env` file in the module directory and read using the `dotenv` Terraform provider:

- Database configuration:

  - `DB_USERNAME`: PostgreSQL user
  - `DB_PASSWORD`: PostgreSQL password
  - `DB_DATABASE`: Database name (defaults to "root_db")

## Data Persistence

NocoDB stores its data in two main volumes:

1. NocoDB application data: `/usr/app/data` in the container, mapped to `${volume_path}/nocodb/data` on the host
2. PostgreSQL data: `/var/lib/postgresql/data` in the container, mapped to `${volume_path}/nocodb/postgres/data` on the host

## Networking

The module creates a dedicated Docker network named `nocodb-network` for communication between the NocoDB components. The NocoDB server container is also attached to any additional networks specified in the `networks` variable, allowing it to communicate with other services in the homelab.

## Dependencies

The NocoDB container depends on PostgreSQL, which includes a healthcheck to ensure it's ready before NocoDB starts.

## Integration with Networking Modules

This service is configured to be exposed through a Cloudflare tunnel for secure remote access, set by `publish_via = "tunnel"`.

## Example Integration in Main Configuration

```hcl
module "nocodb" {
  source           = "./modules/20-services-apps/nocodb"
  volume_path      = module.system_globals.volume_host
  networks         = [module.services.homelab_docker_network_name]
  postgres_password = "your_secure_password"
}

# The service definition is automatically included in the services output
module "services" {
  source = "./modules/services"
  # ...
  service_definitions = [
    module.nocodb.service_definition,
    # Other service definitions
  ]
}
```
