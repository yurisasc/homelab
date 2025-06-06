// Variables for the Cloudflare tunnel module

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for your domain"
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
  description = "List of ingress rules for services to be exposed through the tunnel"
  type = list(object({
    hostname = string
    service  = string
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

