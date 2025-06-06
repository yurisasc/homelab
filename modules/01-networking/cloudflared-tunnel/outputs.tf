// Outputs for the Cloudflare tunnel module

output "tunnel_id" {
  description = "ID of the created Cloudflare tunnel"
  value       = cloudflare_zero_trust_tunnel_cloudflared.this.id
}

output "tunnel_name" {
  description = "Name of the Cloudflare tunnel"
  value       = cloudflare_zero_trust_tunnel_cloudflared.this.name
}

output "tunnel_token" {
  description = "Token for the Cloudflare tunnel"
  value       = cloudflare_zero_trust_tunnel_cloudflared.this.tunnel_token
  sensitive   = true
}

output "cname_target" {
  description = "CNAME target for the tunnel"
  value       = "${cloudflare_zero_trust_tunnel_cloudflared.this.id}.cfargotunnel.com"
}

output "dns_records" {
  description = "Map of created DNS records"
  value       = { for k, v in cloudflare_record.service : k => v.hostname }
}

output "container_name" {
  description = "The name of the Cloudflared tunnel container"
  value       = module.cloudflared.container_name
}

output "container_id" {
  description = "The ID of the Cloudflared tunnel container"
  value       = module.cloudflared.container_id
}

output "image_id" {
  description = "The ID of the Cloudflared image"
  value       = module.cloudflared.image_id
}

output "ip_address" {
  description = "The IP address of the Cloudflared container"
  value       = module.cloudflared.ip_address
}
