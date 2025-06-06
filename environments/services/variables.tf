// Variables for the services environment

// Generic
variable "timezone" {
  description = "Timezone for the system"
  type        = string
}

variable "puid" {
  description = "User ID for the container"
  type        = number
}

variable "pgid" {
  description = "Group ID for the container"
  type        = number
}

variable "data_dir" {
  description = "Base directory for data volumes"
  type        = string
}

variable "default_networks" {
  description = "List of networks to which the container should be attached"
  type        = list(string)
  default     = []
}

// ActualBudget
variable "actualbudget_port" {
  description = "External port for the ActualBudget server"
  type        = number
}

// EmulatorJS
variable "emulatorjs_frontend_port" {
  description = "External port for the EmulatorJS frontend"
  type        = number
}

variable "emulatorjs_config_port" {
  description = "External port for the EmulatorJS configuration interface"
  type        = number
}

variable "emulatorjs_backend_port" {
  description = "External port for the EmulatorJS backend"
  type        = number
}
