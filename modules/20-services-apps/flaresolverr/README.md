# Flaresolverr Module

This module deploys [Flaresolverr](https://github.com/FlareSolverr/FlareSolverr), a proxy server to bypass Cloudflare and Google reCAPTCHA challenges, as a Docker container in the homelab environment.

## Overview

The Flaresolverr module:

- Deploys the `21hsmw/flaresolverr` Docker container
- Provides a shared instance for bypassing challenges
- Supports multiple Docker networks for cross-stack communication

## Usage

```hcl
module "flaresolverr" {
  source   = "./modules/20-services-apps/flaresolverr"
  networks = ["homelab-network", "media-network"]
}
```

## Variables

| Variable    | Description                                                | Type           | Default      |
| ----------- | ---------------------------------------------------------- | -------------- | ------------ |
| `image_tag` | Tag of the Flaresolverr image to use                       | `string`       | `"nodriver"` |
| `networks`  | List of networks to which the container should be attached | `list(string)` | -            |

## Outputs

| Output           | Description                            |
| ---------------- | -------------------------------------- |
| `endpoint`       | The internal HTTP endpoint for service |
| `container_name` | The name of the Flaresolverr container  |

## Service Integration

This module provides an internal service that is consumed by other modules (e.g., Linkwarden, Prowlarr). It is not typically exposed via a public ingress.

```hcl
{
  endpoint = "http://flaresolverr:8191"
}
```

## Configuration

Flaresolverr configuration is managed via environment variables in a `.env` file. See `.env.example` for available options like `LOG_LEVEL` and `CAPTCHA_SOLVER`.

## Example Integration in Main Configuration

```hcl
module "flaresolverr" {
  source   = "${local.module_dir}/20-services-apps/flaresolverr"
  networks = [module.homelab_docker_network.name, module.media_docker_network.name]
}

module "linkwarden" {
  source           = "${local.module_dir}/20-services-apps/linkwarden"
  flaresolverr_url = module.flaresolverr.endpoint
  # ...
}
```
