
variable "cloudflare_api_token" {
  description = "API token for Cloudflare with the necessary permissions"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for the domain"
  type        = string
}

variable "domain" {
  description = "Base domain name (e.g., example.com)"
  type        = string
}
