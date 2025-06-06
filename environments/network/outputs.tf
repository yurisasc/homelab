output "cloudflare_account_id" {
  description = "Cloudflare account ID"
  value       = module.cloudflare_globals.cloudflare_account_id
}

output "cloudflare_zone_id" {
  description = "Cloudflare zone ID"
  value       = module.cloudflare_globals.cloudflare_zone_id
}

output "domain" {
  description = "Base domain name"
  value       = module.cloudflare_globals.domain
}

// Docker network outputs
output "homelab_docker_network_name" {
  description = "Name of the Docker network"
  value       = module.homelab_docker_network.name
}

// Tunnel outputs
output "homelab_cloudflared_tunnel_id" {
  description = "ID of the Cloudflare tunnel"
  value       = module.homelab_cloudflared_tunnel.tunnel_id
}

output "homelab_cloudflared_tunnel_name" {
  description = "Name of the Cloudflare tunnel"
  value       = module.homelab_cloudflared_tunnel.tunnel_name
}

output "homelab_cloudflared_tunnel_cname_target" {
  description = "CNAME target for the tunnel"
  value       = module.homelab_cloudflared_tunnel.cname_target
}
