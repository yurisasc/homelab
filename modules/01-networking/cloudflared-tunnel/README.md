# Cloudflare Tunnel Module

This module creates and manages Cloudflare Tunnels using OpenTofu, automating the entire setup process including:

1. Creating the Cloudflare tunnel
2. Configuring tunnel routing rules
3. Setting up DNS records
4. Deploying the cloudflared tunnel container

## Features

- **Automated Tunnel Management**: Creates and configures Cloudflare tunnels via the API
- **Multiple Service Support**: Route multiple applications through a single tunnel
- **DNS Management**: Automatically creates DNS records for your applications
- **Docker Integration**: Deploys the cloudflared container with proper configuration
- **Secret Management**: Auto-generates tunnel secrets if not provided

## Prerequisites

Before using this module, you need:

1. A Cloudflare account
2. API token with the following permissions:
   - Account.Cloudflare Tunnel:Edit
   - Zone.DNS:Edit
   - Zone.Zone:Read
3. Your Cloudflare account ID and zone ID

## Usage

```hcl
module "homelab_tunnel" {
  source = "./modules/01-networking/cloudflared-tunnel"

  cloudflare_account_id = var.cloudflare_account_id
  cloudflare_zone_id    = var.cloudflare_zone_id

  tunnel_name    = "homelab-tunnel"
  container_name = "cloudflared-homelab"

  ingress_rules = [
    {
      hostname = "dashboard.example.com"
      service  = "http://homepage:3000"
    }
  ]

  service_definitions = [
    {
      name = "homepage"
      subdomains = ["dashboard"]
      endpoint = "http://homepage:3000"
    }
  ]
}
```

## Connecting with the Cloudflare Globals Module

For cleaner code organization, use the globals module:

```hcl
module "cloudflare_globals" {
  source = "./modules/00-globals/cloudflare"
}

module "homelab_tunnel" {
  source = "./modules/01-networking/cloudflared-tunnel"

  cloudflare_account_id = module.cloudflare_globals.cloudflare_account_id
  cloudflare_zone_id    = module.cloudflare_globals.cloudflare_zone_id
  tunnel_name = "homelab-tunnel"
  ingress_rules = [
    {
      hostname = "budget.${module.cloudflare_globals.domain}"
      service  = "http://actualbudget:5006"
    }
  ]
}
```

## Variables

| Name                    | Description                             | Type         | Default                                      |
| ----------------------- | --------------------------------------- | ------------ | -------------------------------------------- |
| `cloudflare_account_id` | Cloudflare account ID                   | string       | (required)                                   |
| `cloudflare_zone_id`    | Cloudflare zone ID for your domain      | string       | (required)                                   |
| `container_name`        | Name of the Cloudflare tunnel container | string       | "" (defaults to "cloudflared-{tunnel_name}") |
| `image_tag`             | Docker image tag for cloudflared        | string       | "latest"                                     |
| `tunnel_name`           | Name of the tunnel                      | string       | (required)                                   |
| `tunnel_secret`         | Secret for the tunnel                   | string       | "" (auto-generated if empty)                 |
| `ingress_rules`         | List of ingress rules                   | list(object) | (optional)                                   |
| `service_definitions`   | List of service definitions. Tunnel will create DNS records for each service with a subdomain.             | list(object) | (optional)                                   |
| `monitoring`            | Enable monitoring via Watchtower        | bool         | true                                         |

### Ingress Rules Object Structure

```hcl
ingress_rules = [
  {
    hostname = "app.example.com"         # FQDN for the service
    service = "http://container:port"    # Internal service URL
    path = "/api/*"                      # Optional path pattern
    create_dns_record = true             # Whether to create DNS record (default: true)
  }
]
```

## Outputs

| Name             | Description                             |
| ---------------- | --------------------------------------- |
| `tunnel_id`      | ID of the created tunnel                |
| `tunnel_name`    | Name of the tunnel                      |
| `tunnel_token`   | Token for the tunnel (sensitive)        |
| `cname_target`   | CNAME target for the tunnel             |
| `dns_records`    | Map of created DNS records              |
| `container_name` | Name of the cloudflared container       |
| `container_id`   | ID of the cloudflared container         |
| `image_id`       | ID of the cloudflared image             |
| `ip_address`     | IP address of the cloudflared container |
