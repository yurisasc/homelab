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

output "data_dir" {
  description = "Base directory for data volumes"
  value       = data.dotenv.system_config.entries.DATA_DIR
}

output "puid" {
  description = "PUID for Docker containers"
  value       = data.dotenv.system_config.entries.PUID
}

output "pgid" {
  description = "PGID for Docker containers"
  value       = data.dotenv.system_config.entries.PGID
}
