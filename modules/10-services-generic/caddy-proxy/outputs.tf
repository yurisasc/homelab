output "container_name" {
  description = "Name of the Caddy proxy container"
  value       = docker_container.caddy.name
}

output "container_ip" {
  description = "IP address of the Caddy container"
  value       = docker_container.caddy.network_data[0].ip_address
}

output "domains" {
  description = "Domains being proxied by Caddy"
  value       = [for site in var.sites : site.domain]
}

output "ready" {
  description = "Boolean indicating if Caddy is ready"
  value       = docker_container.caddy.id != ""
}
