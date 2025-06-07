terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

data "dotenv" "system_config" {}

// Outputs
output "timezone" {
  description = "System timezone"
  value       = data.dotenv.system_config.entries.TIMEZONE
}

output "volume_host" {
  description = "Base directory for host volumes"
  value       = data.dotenv.system_config.entries.VOLUME_HOST
}

output "puid" {
  description = "PUID for Docker containers"
  value       = data.dotenv.system_config.entries.PUID
}

output "pgid" {
  description = "PGID for Docker containers"
  value       = data.dotenv.system_config.entries.PGID
}
