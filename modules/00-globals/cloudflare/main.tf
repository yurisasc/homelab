terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

data "dotenv_sensitive" "cloudflare_credentials" {}
data "dotenv" "cloudflare_config" {}

// Outputs
output "cloudflare_account_id" {
  description = "Cloudflare account ID"
  value       = data.dotenv.cloudflare_config.entries.CLOUDFLARE_ACCOUNT_ID
}

output "cloudflare_zone_id" {
  description = "Cloudflare zone ID"
  value       = data.dotenv.cloudflare_config.entries.CLOUDFLARE_ZONE_ID
}

output "domain" {
  description = "Base domain name"
  value       = data.dotenv.cloudflare_config.entries.DOMAIN
}

output "cloudflare_api_token" {
  description = "API token for Cloudflare"
  value       = data.dotenv_sensitive.cloudflare_credentials.entries.CLOUDFLARE_API_TOKEN
  sensitive   = true
}
