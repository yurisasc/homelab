// Services environment outputs

// ActualBudget
output "actualbudget_container_name" {
  description = "The name of the ActualBudget container"
  value       = module.actualbudget.container_name
}

output "actualbudget_container_id" {
  description = "The ID of the ActualBudget container"
  value       = module.actualbudget.container_id
}

output "actualbudget_local_url" {
  description = "The local URL to access ActualBudget"
  value       = module.actualbudget.local_url
}

// EmulatorJS
output "emulatorjs_container_name" {
  description = "The name of the EmulatorJS container"
  value       = module.emulatorjs.container_name
}

output "emulatorjs_container_id" {
  description = "The ID of the EmulatorJS container"
  value       = module.emulatorjs.container_id
}

output "emulatorjs_frontend_url" {
  description = "The frontend URL for EmulatorJS"
  value       = module.emulatorjs.frontend_url
}

output "emulatorjs_config_url" {
  description = "The configuration URL for EmulatorJS"
  value       = module.emulatorjs.config_url
}
