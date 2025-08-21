variable "container_name" {
  description = "Name of the Docker container"
  type        = string
}

variable "image" {
  description = "Docker image name"
  type        = string
}

variable "tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "keep_image_locally" {
  description = "Whether to keep the Docker image locally after pulling"
  type        = bool
  default     = true
}

variable "restart_policy" {
  description = "Docker restart policy (no, always, unless-stopped, on-failure)"
  type        = string
  default     = "always"
}

variable "network_mode" {
  description = "Docker network mode (bridge, host, etc.)"
  type        = string
  default     = "bridge"
}

variable "ports" {
  description = "List of port mappings"
  type = list(object({
    internal = number
    external = number
    protocol = string
  }))
  default = []
}

variable "networks" {
  description = "List of networks to connect the container to"
  type        = list(string)
  default     = []
}

variable "volumes" {
  description = "List of volume mappings"
  type = list(object({
    host_path      = string
    container_path = string
    read_only      = bool
  }))
  default = []
}

variable "env_vars" {
  description = "Environment variables for the container"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "puid" {
  description = "User ID for the container"
  type        = number
  default     = null
}

variable "pgid" {
  description = "Group ID for the container"
  type        = number
  default     = null
}

variable "labels" {
  description = "Docker container labels"
  type        = map(string)
  default     = {}
}

variable "monitoring" {
  description = "Enable container monitoring via Watchtower"
  type        = bool
  default     = true
}

variable "host_mappings" {
  description = "Additional host mappings for the container (/etc/hosts entries)"
  type = list(object({
    host = string
    ip   = string
  }))
  default = []
}

variable "healthcheck" {
  description = "Container healthcheck configuration"
  type = object({
    test         = list(string)
    interval     = string
    timeout      = string
    start_period = optional(string)
    retries      = number
  })
  default = null
}

// Resource limits
variable "memory_limit" {
  description = "Memory limit for the container (in MB)"
  type        = number
  default     = null
}

variable "memory_swap_limit" {
  description = "Memory swap limit for the container (in MB)"
  type        = number
  default     = null
}

variable "cpu_shares" {
  description = "CPU shares for the container (relative weight)"
  type        = number
  default     = null
}

// Networking options
variable "dns" {
  description = "DNS servers for the container"
  type        = list(string)
  default     = null
}

variable "dns_search" {
  description = "DNS search domains for the container"
  type        = list(string)
  default     = null
}

variable "hostname" {
  description = "Container hostname"
  type        = string
  default     = null
}

variable "domainname" {
  description = "Container domainname"
  type        = string
  default     = null
}

// Execution options
variable "user" {
  description = "User to run commands as inside the container"
  type        = string
  default     = ""
}

variable "working_dir" {
  description = "Working directory inside the container"
  type        = string
  default     = null
}

variable "command" {
  description = "Command to run when starting the container"
  type        = list(string)
  default     = null
}

variable "entrypoint" {
  description = "Entrypoint for the container"
  type        = list(string)
  default     = null
}

variable "group_add" {
  description = "Additional groups to add to the container"
  type        = list(string)
  default     = []
}

variable "privileged" {
  description = "Run container in privileged mode"
  type        = bool
  default     = false
}

// Linux capabilities controls
variable "capabilities_add" {
  description = "Linux capabilities to add to the container"
  type        = list(string)
  default     = []
}

variable "capabilities_drop" {
  description = "Linux capabilities to drop from the container"
  type        = list(string)
  default     = []
}

// Devices to pass through to container
variable "devices" {
  description = "List of device mappings for the container"
  type = list(object({
    host_path      = string
    container_path = string
    permissions    = string
  }))
  default = []
}

variable "destroy_grace_seconds" {
  description = "Grace period in seconds before the container is destroyed"
  type        = number
  default     = 10
}

// Logging options
variable "log_driver" {
  description = "Log driver for the container"
  type        = string
  default     = "json-file"
}

variable "log_opts" {
  description = "Log driver options"
  type        = map(string)
  default = {
    max-size = "10m"
    max-file = "3"
  }
}
