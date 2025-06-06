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

// Watchtower
variable "watchtower_enable_notifications" {
  description = "Enable Watchtower update notifications"
  type        = bool
  default     = false
}

variable "watchtower_notification_url" {
  description = "Webhook URL for Watchtower notifications (Discord, Slack, etc.)"
  type        = string
  sensitive   = true  // This flags the variable as sensitive in logs and outputs
  default     = ""
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

// ActualBudget
variable "actualbudget_port" {
  description = "External port for the ActualBudget server"
  type        = number
}

// Cloudflare
variable "cloudflare_api_token" {
  description = "API token for Cloudflare with tunnel, DNS, and zone management permissions"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for your domain"
  type        = string
}

variable "domain" {
  description = "Base domain name (e.g., example.com)"
  type        = string
}

