# Caddy Proxy Module

This module creates a Caddy reverse proxy server that dynamically configures itself based on service definitions passed to it.

## Overview

The Caddy Proxy module:
- Accepts service definitions that specify whether to expose them via reverse proxy
- Dynamically generates Caddyfile configuration from these service definitions
- Supports custom Caddy configuration blocks per service
- Deploys a Caddy container with the generated configuration
- Manages TLS certificates automatically using Let's Encrypt
- Creates DNS records for services with configurable Cloudflare proxying settings

## Usage

### Basic Integration

Add the module to your main Terraform configuration:

```hcl
module "homelab_caddy_proxy" {
  source             = "./modules/01-networking/caddy-proxy"
  domain             = "yourdomain.com"
  tls_email          = "your-email@example.com"  # For Let's Encrypt
  container_name     = "caddy-proxy"
  cloudflare_zone_id = module.cloudflare_globals.cloudflare_zone_id
  external_ip        = module.cloudflare_globals.external_ip
  service_definitions = module.services.service_definitions
  networks           = ["your-docker-network"]
}
```

### Service Definition Format

Services should include the following fields to be properly exposed through Caddy:

```hcl
{
  name       = "service-name"
  endpoint   = "service-container:port"
  subdomains = ["app", "dashboard"]  # Will create app.yourdomain.com, dashboard.yourdomain.com
  
  # Specify how to publish this service: "tunnel", "reverse_proxy", or "both" (default)
  publish_via = "both"
  
  # Control whether the DNS record is proxied through Cloudflare (default: true)
  proxied = true
  
  # Option 1: Simplified Caddy configuration via options
  caddy_options = {
    "health_path" = "/health"
    "health_interval" = "30s"
    "header_up X-Real-IP" = "{http.request.remote}"
    # Additional reverse_proxy options as needed
  }
  
  # Option 2: Full custom Caddy configuration (takes precedence if both are provided)
  caddy_config = <<-EOT
    # Raw Caddy configuration goes here
    reverse_proxy /api/* api-backend:8080
    reverse_proxy /* frontend:3000
    header X-Powered-By "My Awesome Homelab"
    log {
      output file /var/log/access.log
    }
  EOT
}
```

The `publish_via` field controls which networking module(s) will expose the service:
- `"tunnel"`: Service will only be published via Cloudflare tunnel
- `"reverse_proxy"`: Service will only be exposed via Caddy reverse proxy
- `"both"`: Service will be published via both methods (default)

## Variables

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `container_name` | The name of the Caddy container | `string` | `""` (generates "caddy-proxy") |
| `image_tag` | The tag of the Caddy Docker image to use | `string` | `"latest"` |
| `domain` | The domain name to use for services | `string` | - |
| `tls_email` | Email address for Let's Encrypt | `string` | - |
| `service_definitions` | List of service definitions to evaluate | `list(object)` | - |
| `networks` | List of Docker networks to connect to | `list(string)` | `[]` |
| `monitoring` | DEPRECATED: Previously enabled container monitoring via Watchtower. Now a no-op. | `bool` | `false` |
| `cloudflare_zone_id` | Cloudflare Zone ID for creating DNS records | `string` | `""` |
| `external_ip` | External IP address for A records | `string` | `""` |

## Outputs

| Output | Description |
|--------|-------------|
| `container_name` | The name of the deployed Caddy container |
| `config_hash` | The SHA256 hash of the generated Caddyfile content |
| `service_sites` | Map of generated Caddy site configurations |

## Example Service Integration

### Basic Service with Default Settings

```hcl
# Example based on ntfy (reverse-proxy only with direct IP exposure)
output "service_definition" {
  description = "Service definition for a notification service"
  value = {
    name         = "ntfy"
    primary_port = 80
    endpoint     = "http://ntfy:80"
    subdomains   = ["ntfy"]
    publish_via  = "reverse_proxy"  # Only expose via Caddy reverse proxy
    proxied      = false            # Don't proxy through Cloudflare (expose direct IP)
  }
}
```

### Service with Custom Caddy Configuration

```hcl
# Example showing a service with custom Caddy configuration
output "service_definition" {
  description = "Service definition with custom Caddy configuration"
  value = {
    name         = "custom-service"
    primary_port = 8080
    endpoint     = "http://custom-service:8080"
    subdomains   = ["custom"]
    publish_via  = "reverse_proxy"
    proxied      = true  # Use Cloudflare proxying (default)
    caddy_config = <<-EOT
      # Handle API requests specially
      handle /api/* {
        reverse_proxy custom-service:8080 {
          header_up X-Real-IP {remote}
        }
      }
      
      # Handle all other requests
      handle {
        reverse_proxy custom-service:8080
        header +Access-Control-Allow-Origin "*"
      }
    EOT
  }
}
```
