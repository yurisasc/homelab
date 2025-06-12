terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

data "dotenv" "system_config" {}

// Outputs
output "tls_email" {
  description = "TLS email"
  value       = data.dotenv.system_config.entries.TLS_EMAIL
}
