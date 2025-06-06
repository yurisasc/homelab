output "container_name" {
  description = "The name of the ActualBudget container"
  value       = module.actualbudget.container_name
}

output "container_id" {
  description = "The ID of the ActualBudget container"
  value       = module.actualbudget.container_id
}

output "image_id" {
  description = "The ID of the ActualBudget image"
  value       = module.actualbudget.image_id
}

output "ip_address" {
  description = "The IP address of the ActualBudget container"
  value       = module.actualbudget.ip_address
}

output "local_url" {
  description = "The local URL to access the ActualBudget interface"
  value       = "http://localhost:${var.port}"
}
