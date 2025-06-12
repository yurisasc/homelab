# ActualBudget Module

This module deploys [ActualBudget](https://actualbudget.com/), a personal finance and budgeting application, as a Docker container in the homelab environment.

## Overview

The ActualBudget module:

- Deploys the `actualbudget/actual-server` Docker container
- Persists data to a volume on the host
- Provides service definition for integration with networking modules

## Usage

```hcl
module "actualbudget" {
  source      = "./modules/20-services-apps/actualbudget"
  volume_path = "/path/to/volumes/actualbudget"
  networks    = ["homelab-network"]
}
```

## Variables

| Variable      | Description                                                | Type           | Default    |
| ------------- | ---------------------------------------------------------- | -------------- | ---------- |
| `image_tag`   | Tag of the ActualBudget image to use                       | `string`       | `"latest"` |
| `volume_path` | Host path for ActualBudget data volume                     | `string`       | -          |
| `networks`    | List of networks to which the container should be attached | `list(string)` | -          |

## Outputs

| Output               | Description                                                |
| -------------------- | ---------------------------------------------------------- |
| `service_definition` | Service definition for integration with networking modules |

## Service Definition

This module outputs a service definition that is used by the networking modules to expose the service.

```hcl
{
  name         = "actualbudget"
  primary_port = 5006
  endpoint     = "http://actualbudget:5006"
  subdomains   = ["budget"]
  publish_via  = "tunnel"  # Only publish through Cloudflare tunnel
}
```

## Data Persistence

ActualBudget stores its data in the `/data` directory inside the container. This is mapped to a volume on the host at `${volume_path}/data`.

## Integration with Networking Modules

This service is configured to be exposed through a Cloudflare tunnel for secure remote access, set by `publish_via = "tunnel"`.

## Example Integration in Main Configuration

```hcl
module "actualbudget" {
  source      = "./modules/20-services-apps/actualbudget"
  volume_path = module.system_globals.volume_host
  networks    = [module.services.homelab_docker_network_name]
}

# The service definition is automatically included in the services output
module "services" {
  source = "./modules/services"
  # ...
  service_definitions = [
    module.actualbudget.service_definition,
    # Other service definitions
  ]
}
```
