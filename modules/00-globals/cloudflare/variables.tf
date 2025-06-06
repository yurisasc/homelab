variable "cloudflare_api_token" {
  description = "API token for Cloudflare with tunnel, DNS, and zone management permissions"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for your domain"
  type        = string
}

variable "domain" {
  description = "Base domain name (e.g., example.com)"
  type        = string
}