variable "container_name" {
  description = "Name for the Watchtower container"
  type        = string
  default     = "watchtower"
}

variable "image_tag" {
  description = "The tag for the Watchtower container image"
  type        = string
  default     = "latest"
}

variable "restart_policy" {
  description = "Restart policy for the container"
  type        = string
  default     = "unless-stopped"
}

variable "timezone" {
  description = "Timezone for the container"
  type        = string
  default     = "Etc/UTC"
}

variable "cleanup" {
  description = "Remove old images after updating"
  type        = bool
  default     = true
}

variable "poll_interval" {
  description = "Poll interval (in seconds) for checking for updates"
  type        = number
  default     = 86400  // Default: check once per day
}

variable "include_stopped" {
  description = "Include stopped containers when checking for updates"
  type        = bool
  default     = false
}

variable "revive_stopped" {
  description = "Restart stopped containers after updating"
  type        = bool
  default     = false
}

variable "rolling_restart" {
  description = "Restart containers one by one instead of all at once"
  type        = bool
  default     = true
}

variable "notification_url" {
  description = "URL for sending update notifications via shoutrrr"
  type        = string
  default     = ""
}

variable "enable_notifications" {
  description = "Enable shoutrrr notifications"
  type        = bool
  default     = false
}

variable "additional_env_vars" {
  description = "Additional environment variables for Watchtower"
  type        = map(string)
  default     = {}
}

variable "additional_volumes" {
  description = "Additional volumes to mount in the container"
  type = list(object({
    host_path      = string
    container_path = string
    read_only      = bool
  }))
  default = []
}

variable "labels" {
  description = "Labels to set on the container"
  type        = map(string)
  default     = {}
}

variable "ports" {
  description = "Ports to expose (Watchtower typically doesn't need ports exposed)"
  type = list(object({
    internal = number
    external = number
    protocol = string
  }))
  default = []
}

variable "monitoring" {
  description = "Enable monitoring for the container"
  type        = bool
  default     = true
}
