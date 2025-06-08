terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

data "dotenv" "smtp_config" {}

// Outputs
output "mail_from" {
  description = "Mail from address"
  value       = data.dotenv.smtp_config.entries.MAIL_FROM
}

output "mail_host" {
  description = "Mail host"
  value       = data.dotenv.smtp_config.entries.MAIL_HOST
}

output "mail_port" {
  description = "Mail port"
  value       = data.dotenv.smtp_config.entries.MAIL_PORT
}

output "mail_username" {
  description = "Mail username"
  value       = data.dotenv.smtp_config.entries.MAIL_USERNAME
}

output "mail_password" {
  description = "Mail password"
  value       = data.dotenv.smtp_config.entries.MAIL_PASSWORD
}
