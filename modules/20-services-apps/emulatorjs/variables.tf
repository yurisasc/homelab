variable "container_name" {
  description = "Name for the EmulatorJS container"
  type        = string
  default     = "emulatorjs"
}

variable "image_tag" {
  description = "The tag for the EmulatorJS container image"
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

variable "puid" {
  description = "User ID the container will run as"
  type        = number
  default     = 1000
}

variable "pgid" {
  description = "Group ID the container will run as"
  type        = number
  default     = 1000
}

variable "config_volume_path" {
  description = "Host path for the EmulatorJS config directory"
  type        = string
}

variable "data_volume_path" {
  description = "Host path for the EmulatorJS data directory"
  type        = string
}

variable "frontend_port" {
  description = "External port for the EmulatorJS frontend"
  type        = number
  default     = 3000
}

variable "config_port" {
  description = "External port for the EmulatorJS configuration interface"
  type        = number
  default     = 8080
}

variable "backend_port" {
  description = "External port for the EmulatorJS backend"
  type        = number
  default     = 4001
}

variable "additional_env_vars" {
  description = "Additional environment variables for EmulatorJS"
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

variable "monitoring" {
  description = "Enable monitoring for the container via Watchtower"
  type        = bool
  default     = true
}
