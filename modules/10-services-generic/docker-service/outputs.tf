output "container_name" {
  description = "Name of the Docker container"
  value       = docker_container.service_container.name
}

output "container_id" {
  description = "ID of the Docker container"
  value       = docker_container.service_container.id
}

output "image_id" {
  description = "ID of the Docker image"
  value       = docker_image.service_image.id
}

output "ip_address" {
  description = "IP address of the container (if applicable)"
  value       = docker_container.service_container.network_data != null ? docker_container.service_container.network_data[0].ip_address : null
}

output "container_ports" {
  description = "Published ports of the container"
  value       = docker_container.service_container.ports
}
