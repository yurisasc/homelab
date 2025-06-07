// Variables for the Cloudflare tunnel module
variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for your domain"
  type        = string
}

variable "domain" {
  description = "The domain name to use for creating DNS records"
  type        = string
}

variable "container_name" {
  description = "Name of the Cloudflare tunnel container"
  type        = string
  default     = ""
}

variable "image_tag" {
  description = "Docker image tag for cloudflare/cloudflared"
  type        = string
  default     = "latest"
}

variable "tunnel_name" {
  description = "Name of the Cloudflare tunnel"
  type        = string
}

variable "tunnel_secret" {
  description = "Secret for the Cloudflare tunnel (will be auto-generated if empty)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "ingress_rules" {
  description = "List of ingress rules to configure manually"
  type = list(object({
    hostname = string
    service  = string
  }))
  default = []
}

variable "service_definitions" {
  description = "List of service definitions containing name, endpoints and hostname configuration"
  type = list(object({
    name         = string
    primary_port = number
    endpoint     = string
    hostnames    = optional(list(string), [])
  }))
  default = []
}

variable "monitoring" {
  description = "Enable monitoring via Watchtower"
  type        = bool
  default     = true
}

variable "networks" {
  description = "List of networks to connect the container to"
  type        = list(string)
  default     = []
}

