variable "volume_path" {
  description = "Base directory for volumes (APP_DATA)"
  type        = string
}

variable "data_root" {
  description = "Root directory for media data (DATA_ROOT)"
  type        = string
}

variable "download_root" {
  description = "Directory for downloads (DOWNLOAD_ROOT)"
  type        = string
}

variable "user_id" {
  description = "User ID for container permissions"
  type        = string
  default     = "1000"
}

variable "group_id" {
  description = "Group ID for container permissions"
  type        = string
  default     = "1000"
}

variable "timezone" {
  description = "Timezone for the containers"
  type        = string
  default     = "UTC"
}

variable "hostname" {
  description = "Hostname for the Jellyfin PublishedServerUrl"
  type        = string
}

variable "sonarr_api_key" {
  description = "API key for Sonarr"
  type        = string
  sensitive   = true
}

variable "radarr_api_key" {
  description = "API key for Radarr"
  type        = string
  sensitive   = true
}

variable "networks" {
  description = "List of additional networks to which containers should be attached"
  type        = list(string)
  default     = []
}
