// Outputs for the EmulatorJS module

output "container_name" {
  description = "Name of the created EmulatorJS container"
  value       = module.emulatorjs.container_name
}

output "container_id" {
  description = "ID of the created EmulatorJS container"
  value       = module.emulatorjs.container_id
}

output "image_id" {
  description = "ID of the EmulatorJS image used"
  value       = module.emulatorjs.image_id
}

output "frontend_url" {
  description = "URL to access the EmulatorJS frontend interface"
  value       = "http://localhost:${var.frontend_port}"
}

output "config_url" {
  description = "URL to access the EmulatorJS web configuration interface"
  value       = "http://localhost:${var.config_port}"
}
