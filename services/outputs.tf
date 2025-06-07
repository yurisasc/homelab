// Services environment outputs

// Consolidated service definitions for networking
output "service_definitions" {
  description = "Service definitions for all services"
  value = [
    module.actualbudget.service_definition,
    module.emulatorjs.service_definition
  ]
}

output "homelab_docker_network_name" {
  description = "The name of the Docker network"
  value       = module.homelab_docker_network.name
}
