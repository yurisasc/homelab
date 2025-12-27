# Fossflow Module

This module deploys [Fossflow](https://github.com/stnsmith/fossflow), an open-source flow diagram application, as a Docker container in the homelab environment.

## Overview

The Fossflow module:

- Deploys the `stnsmith/fossflow` Docker container
- Persists diagram data to a volume on the host
- Provides service definition for integration with networking modules
- Exposes the service on a configurable host port

## Usage

```hcl
module "fossflow" {
  source      = "./modules/20-services-apps/fossflow"
  volume_path = "/path/to/volumes/fossflow"
  networks    = ["homelab-network"]
  host_port   = 31845
}
```

## Variables

| Variable                  | Description                                                | Type           | Default     |
| ------------------------ | ---------------------------------------------------------- | -------------- | ----------- |
| `image_tag`              | Tag of the fossflow image to use                           | `string`       | `"latest"`  |
| `volume_path`            | Host path for fossflow data volume                         | `string`       | -           |
| `networks`               | List of networks to which the container should be attached | `list(string)` | `[]`        |
| `host_port`              | Host port to publish fossflow on                           | `number`       | `31845`     |
| `enable_server_storage` | Whether to enable server storage                           | `bool`         | `true`      |
| `enable_git_backup`      | Whether to enable git backup                               | `bool`         | `false`     |

## Outputs

| Output               | Description                                                |
| -------------------- | ---------------------------------------------------------- |
| `service_definition` | Service definition for integration with networking modules |

## Service Definition

This module outputs a service definition that is used by the networking modules to expose the service.

```hcl
{
  name         = "fossflow"
  primary_port = 80
  endpoint     = "http://fossflow:80"
  subdomains   = ["fossflow"]
  publish_via  = "tunnel"
  proxied      = true
}
```

## Data Persistence

Fossflow stores its diagram data in the `/data/diagrams` directory inside the container. This is mapped to a volume on the host at `${volume_path}/diagrams`.

## Integration with Networking Modules

This service is configured to be exposed through a Cloudflare tunnel for secure remote access, set by `publish_via = "tunnel"`.

## Example Integration in Main Configuration

```hcl
module "fossflow" {
  source      = "./modules/20-services-apps/fossflow"
  volume_path = "${local.volume_host}/fossflow"
  networks    = [module.homelab_docker_network.name]
  host_port   = 31845
}

# The service definition is automatically included in the services output
module "services" {
  source = "./modules/services"
  # ...
  service_definitions = [
    module.fossflow.service_definition,
    # Other service definitions
  ]
}
```
