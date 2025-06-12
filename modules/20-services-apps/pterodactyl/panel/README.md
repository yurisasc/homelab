# Pterodactyl Panel Module

This module deploys [Pterodactyl Panel](https://pterodactyl.io/), a game server management panel, as Docker containers in the homelab environment.

## Overview

The Pterodactyl Panel module:

- Deploys three Docker containers:
  - `pterodactyl-panel`: The main web UI and API server
  - `pterodactyl-db`: A MariaDB database backend
  - `pterodactyl-cache`: A Redis cache server
- Creates a dedicated Docker network (`ptero-panel`) for container communication
- Persists data to volumes on the host
- Provides service definition for integration with networking modules

## Usage

```hcl
module "pterodactyl_panel" {
  source      = "./modules/20-services-apps/pterodactyl/panel"
  volume_path = "/path/to/volumes/pterodactyl/panel"
  networks    = ["homelab-network"]
}
```

## Variables

| Variable      | Description                                                | Type           | Default    |
| ------------- | ---------------------------------------------------------- | -------------- | ---------- |
| `image_tag`   | Tag of the Pterodactyl Panel image to use                  | `string`       | `"latest"` |
| `volume_path` | Host path for Pterodactyl Panel volumes                    | `string`       | -          |
| `networks`    | List of networks to which the panel should be attached     | `list(string)` | `[]`       |

## Outputs

| Output               | Description                                                |
| -------------------- | ---------------------------------------------------------- |
| `service_definition` | Service definition for integration with networking modules |

## Service Definition

This module outputs a service definition that is used by the networking modules to expose the service.

```hcl
{
  name         = "pterodactyl-panel"
  primary_port = 80
  endpoint     = "http://pterodactyl-panel:80"
  subdomains   = ["gameservers"]
  publish_via  = "tunnel"
}
```

## Environment Variables

Pterodactyl Panel requires several environment variables to function properly. These are stored in a `.env` file in the module directory and read using the `dotenv` Terraform provider. Key variables include:

- Panel Configuration:
  - `APP_URL`: The URL where the panel will be accessed
  - `APP_TIMEZONE`: The timezone for the application
  - `APP_SERVICE_AUTHOR`: Service author information

- Database Configuration:
  - `MYSQL_PASSWORD`: Database password
  - `MYSQL_ROOT_PASSWORD`: Database root password
  - `MYSQL_DATABASE`: Database name
  - `MYSQL_USER`: Database username

- Mail Configuration:
  - Mail settings are automatically sourced from the global SMTP module

## Data Persistence

Pterodactyl Panel stores its data in multiple volumes:

1. Application data: `/app/var` in the container, mapped to `${volume_path}/var` on the host
2. Nginx configuration: `/etc/nginx/http.d` in the container, mapped to `${volume_path}/nginx` on the host
3. SSL certificates: `/etc/letsencrypt` in the container, mapped to `${volume_path}/certs` on the host
4. Logs: `/app/storage/logs` in the container, mapped to `${volume_path}/logs` on the host
5. Database data: `/var/lib/mysql` in the MariaDB container, mapped to `${volume_path}/database` on the host

## Networking

The module creates a dedicated Docker network named `ptero-panel` for communication between the panel, database, and cache containers. The panel container is also attached to any additional networks specified in the `networks` variable, allowing it to communicate with other services in the homelab.

## Integration with Networking Modules

This service is configured to be exposed through a Cloudflare tunnel for secure remote access, set by `publish_via = "tunnel"`.

## Example Integration in Main Configuration

```hcl
module "pterodactyl_panel" {
  source      = "./modules/20-services-apps/pterodactyl/panel"
  volume_path = module.system_globals.volume_host
  networks    = [module.services.homelab_docker_network_name]
}

# The service definition is automatically included in the services output
module "services" {
  source = "./modules/services"
  # ...
  service_definitions = [
    module.pterodactyl_panel.service_definition,
    # Other service definitions
  ]
}
```
