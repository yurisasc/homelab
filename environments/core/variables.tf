// Generic
variable "timezone" {
  description = "Timezone for the system"
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
  sensitive   = true
  default     = ""
}
