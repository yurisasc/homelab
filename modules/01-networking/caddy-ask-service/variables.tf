variable "container_name" {
  description = "Name of the ask service container"
  type        = string
  default     = "caddy-ask"
}

variable "volume_path" {
  description = "Base directory for ask service data"
  type        = string
}

variable "allowlist_path" {
  description = "Host path to the allowlist file (allowed-domains.txt)"
  type        = string
}

variable "networks" {
  description = "Networks to attach the container to"
  type        = list(string)
  default     = []
}

variable "monitoring" {
  description = "DEPRECATED: Previously enabled monitoring labels. Now a no-op."
  type        = bool
  default     = false
}
