// Root outputs that expose important information from each environment

// Network environment outputs
output "cloudflare_domain" {
  description = "Base domain for the homelab"
  value       = module.network.domain
}

output "homelab_cloudflared_tunnel_name" {
  description = "Name of the Cloudflare tunnel"
  value       = module.network.homelab_cloudflared_tunnel_name
}

output "homelab_cloudflared_tunnel_cname_target" {
  description = "CNAME target for the Cloudflare tunnel"
  value       = module.network.homelab_cloudflared_tunnel_cname_target
}

// Service URLs
output "actualbudget_local_url" {
  description = "Local URL for accessing ActualBudget"
  value       = module.services.actualbudget_local_url
}

output "emulatorjs_frontend_url" {
  description = "URL for the EmulatorJS frontend"
  value       = module.services.emulatorjs_frontend_url
}

output "emulatorjs_config_url" {
  description = "URL for the EmulatorJS configuration"
  value       = module.services.emulatorjs_config_url
}
