output "cloudflare_account_id" {
  description = "Cloudflare account ID"
  value       = var.cloudflare_account_id
}

output "cloudflare_zone_id" {
  description = "Cloudflare zone ID"
  value       = var.cloudflare_zone_id
}

output "domain" {
  description = "Base domain name"
  value       = var.domain
}

output "cloudflare_api_token" {
  description = "API token for Cloudflare"
  value       = var.cloudflare_api_token
  sensitive   = true
}
