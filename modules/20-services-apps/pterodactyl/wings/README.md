# Pterodactyl Wings Module

This module deploys [Pterodactyl Wings](https://pterodactyl.io/wings/), the game server agent component of Pterodactyl, as a Docker container in the homelab environment.

## Overview

The Pterodactyl Wings module:

- Deploys the `pterodactyl-wings` Docker container
- Creates a dedicated Docker network (`ptero-wings`) for game server communication
- Persists data to volumes on the host
- Provides service definition for integration with networking modules
- Runs with privileged mode to manage game server containers

## Usage

```hcl
module "pterodactyl_wings" {
  source      = "./modules/20-services-apps/pterodactyl/wings"
  volume_path = "/path/to/volumes/pterodactyl/wings"
  networks    = ["homelab-network"]
}
```

## Variables

| Variable      | Description                                             | Type           | Default     |
| ------------- | ------------------------------------------------------- | -------------- | ----------- |
| `image_tag`   | Tag of the Pterodactyl Wings image to use               | `string`       | `"v1.11.3"` |
| `volume_path` | Host path for Pterodactyl Wings volumes                 | `string`       | -           |
| `networks`    | List of networks to which wings should be attached      | `list(string)` | `[]`        |

## Outputs

| Output               | Description                                                |
| -------------------- | ---------------------------------------------------------- |
| `service_definition` | Service definition for integration with networking modules |

## Service Definition

This module outputs a service definition that is used by the networking modules to expose the service.

```hcl
{
  name         = "pterodactyl-wings"
  primary_port = 443
  endpoint     = "http://pterodactyl-wings:443"
  subdomains   = ["wings"]
  publish_via  = "tunnel"
}
```

## Environment Variables

Pterodactyl Wings uses the following environment variables:

- `TZ`: Timezone (set to Australia/Brisbane)
- `WINGS_UID`: User ID for wings process (988)
- `WINGS_GID`: Group ID for wings process (988)
- `WINGS_USERNAME`: Username for wings process ("pterodactyl")

## Data Persistence

Pterodactyl Wings uses several volume mounts:

1. Docker socket: `/var/run/docker.sock` (for controlling game server containers)
2. Docker containers: `/var/lib/docker/containers/` (for accessing container information)
3. SSL certificates: `/etc/ssl/certs` (mounted read-only)
4. Wings configuration: `/etc/pterodactyl/` in the container, mapped to `${volume_path}/etc`
5. Wings data: `/var/lib` in the container, mapped to `${volume_path}/var/lib`
6. Logs: `/var/log/pterodactyl/` in the container, mapped to `${volume_path}/var/log`
7. Temporary files: `${volume_path}/tmp` in the container and host

## Networking

The module creates a dedicated Docker network named `ptero-wings` for game server communication. This network is configured with the subnet `172.21.0.0/16` and is made attachable to allow game server containers to connect to it. The wings container is also attached to any additional networks specified in the `networks` variable.

## Integration with Networking Modules

This service is configured to be exposed through a Cloudflare tunnel for secure remote access, set by `publish_via = "tunnel"`.

## Example Integration in Main Configuration

```hcl
module "pterodactyl_wings" {
  source      = "./modules/20-services-apps/pterodactyl/wings"
  volume_path = module.system_globals.volume_host
  networks    = [module.services.homelab_docker_network_name]
}

# The service definition is automatically included in the services output
module "services" {
  source = "./modules/services"
  # ...
  service_definitions = [
    module.pterodactyl_wings.service_definition,
    # Other service definitions
  ]
}
```
