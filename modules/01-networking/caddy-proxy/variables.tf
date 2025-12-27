variable "container_name" {
  description = "The name of the Caddy container"
  type        = string
  default     = ""
}

variable "image_tag" {
  description = "The tag of the Caddy Docker image to use"
  type        = string
  default     = "latest"
}

variable "volume_path" {
  description = "Base directory for volumes"
  type        = string
}

variable "domain" {
  description = "The domain name to use for services"
  type        = string
}

variable "tls_email" {
  description = "Email address to use for TLS certificate generation with Let's Encrypt"
  type        = string
}

variable "service_definitions" {
  description = "List of service definitions to evaluate for exposure through Caddy"
  type = list(object({
    name          = string
    endpoint      = string
    subdomains    = optional(list(string), [])
    publish_via   = optional(string)
    caddy_config  = optional(string, "")
    caddy_options = optional(map(string), {})
    proxied       = optional(bool, true) # Controls whether the DNS record is proxied through Cloudflare
  }))
}

variable "networks" {
  description = "List of Docker networks to connect the Caddy container to"
  type        = list(string)
  default     = []
}

variable "monitoring" {
  description = "Whether to enable monitoring for the Caddy container"
  type        = bool
  default     = false
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for creating DNS records"
  type        = string
  default     = ""
}

variable "external_ip" {
  description = "External IP address for A records when using create_dns_records"
  type        = string
  default     = ""
}

variable "enable_ondemand_tls" {
  description = "Enable on-demand TLS for dynamic domain routing (requires ask_endpoint_url)"
  type        = bool
  default     = false
}

variable "ask_endpoint_url" {
  description = "URL of the ask endpoint for on-demand TLS permission checks (e.g., http://caddy-ask:8080/cgi-bin/allow)"
  type        = string
  default     = ""
}

variable "dokploy_traefik_endpoint" {
  description = "Internal endpoint for Dokploy's Traefik (e.g., http://dokploy-traefik:80)"
  type        = string
  default     = ""
}
