variable "container_name" {
  description = "Name of the ActualBudget container"
  type        = string
  default     = "actualbudget"
}

variable "timezone" {
  description = "Timezone for the container"
  type        = string
  default     = "UTC"
}

variable "image_tag" {
  description = "Tag of the ActualBudget image to use"
  type        = string
  default     = "latest"
}

variable "port" {
  description = "External port for ActualBudget server"
  type        = number
  default     = 5006
}

variable "data_volume_path" {
  description = "Host path for ActualBudget data volume"
  type        = string
}

variable "puid" {
  description = "User ID for the container"
  type        = number
  default     = 1000
}

variable "pgid" {
  description = "Group ID for the container"
  type        = number
  default     = 1000
}

variable "monitoring" {
  description = "Enable monitoring for the container via Watchtower"
  type        = bool
  default     = true
}

variable "networks" {
  description = "List of networks to which the container should be attached"
  type        = list(string)
  default     = []
}