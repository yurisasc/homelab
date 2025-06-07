// Outputs for Docker Network module
output "network_id" {
  description = "The ID of the Docker network"
  value       = docker_network.this.id
}

output "name" {
  description = "The name of the Docker network"
  value       = docker_network.this.name
}

output "network_driver" {
  description = "The driver of the Docker network"
  value       = docker_network.this.driver
}

output "ipam_config" {
  description = "The IPAM configuration of the Docker network"
  value       = docker_network.this.ipam_config
}
