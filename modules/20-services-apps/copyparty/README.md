# Copyparty Module

This module deploys [copyparty](https://github.com/9001/copyparty), a portable file server.

## Overview

The copyparty module:

- Deploys one Docker container: `copyparty`.
- Mounts a volume for configuration and another for the files to be shared.
- Provides a service definition for integration with networking modules.

## Usage

```hcl
module "copyparty" {
  source         = "./modules/20-services-apps/copyparty"
  fileshare_path = "/path/to/your/fileshare/top/folder"
  config_path    = "/path/to/copyparty/config"
  networks       = ["homelab-network"]
}
```

## Variables

| Variable         | Description                                                 |
| ---------------- | ----------------------------------------------------------- |
| `image_tag`      | Tag of the copyparty image to use                           |
| `fileshare_path` | Host path for the top folder of the file share              |
| `config_path`    | Host path for copyparty configuration files                 |
| `networks`       | List of additional networks to which copyparty should be attached |
| `puid`           | User ID to run the container as                             |
| `pgid`           | Group ID to run the container as                            |

## Outputs

| Output               | Description                                                |
| -------------------- | ---------------------------------------------------------- |
| `service_definition` | Service definition for integration with networking modules |

## Service Definition

This module outputs a service definition that is used by the networking modules to expose the service.

```hcl
{
  name         = "copyparty"
  primary_port = 3923
  endpoint     = "http://copyparty:3923"
  subdomains   = ["files"]
  publish_via  = "reverse_proxy"
}
```

## Data Persistence

Copyparty uses two volumes:

1.  Configuration: `/cfg` in the container, mapped to `var.config_path` on the host.
2.  File Share: `/w` in the container, mapped to `var.fileshare_path` on the host.

## Integration with Networking Modules

This service is configured to be exposed through the Caddy reverse proxy, set by `publish_via = "reverse_proxy"`.

## Example Integration in Main Configuration

```hcl
module "copyparty" {
  source         = "./modules/20-services-apps/copyparty"
  fileshare_path = "/mnt/storage/files"
  config_path    = "${module.system_globals.volume_host}/copyparty/config"
  networks       = [module.services.homelab_docker_network_name]
}

# The service definition is automatically included in the services output
module "services" {
  source = "./modules/services"
  # ...
  service_definitions = [
    module.copyparty.service_definition,
    # Other service definitions
  ]
}
```
