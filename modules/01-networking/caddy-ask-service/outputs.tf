output "endpoint" {
  description = "Internal endpoint URL for the ask service"
  value       = "http://${local.container_name}:${local.internal_port}"
}

output "container_name" {
  description = "Name of the ask service container"
  value       = local.container_name
}
