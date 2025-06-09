variable "container_name" {
  description = "The name of the Caddy container"
  type        = string
  default     = "caddy-proxy"
}

variable "http_port" {
  description = "External HTTP port mapping"
  type        = number
  default     = 9080
}

variable "https_port" {
  description = "External HTTPS port mapping"
  type        = number
  default     = 9443
}

variable "admin_port" {
  description = "External admin port mapping"
  type        = number
  default     = 9081
}

variable "image" {
  description = "The image to use for the Caddy container"
  type        = string
  default     = "caddy"
}

variable "tag" {
  description = "The tag of the Caddy image"
  type        = string
  default     = "latest"
}

variable "volume_path" {
  description = "Base directory for volumes"
  type        = string
  default     = "/mnt/appdata/caddy"
}

variable "monitoring" {
  description = "Enable or disable monitoring"
  type        = bool
  default     = true
}

variable "networks" {
  description = "List of networks to attach to the Caddy container"
  type        = list(string)
  default     = []
}

variable "sites" {
  description = "List of sites to proxy"
  type = list(object({
    domain = string      # Domain name (e.g. deploy.yuris.dev)
    routes = list(object({
      path        = string       # Path to match (e.g. "/app/*" or "/" for root)
      target_host = string       # Target host (e.g. coolify)
      target_port = number       # Target port (e.g. 8080)
      websocket   = bool         # Whether this route should be treated as websocket
    }))
  }))
}
