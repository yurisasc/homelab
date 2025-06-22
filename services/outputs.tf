// Services environment outputs

// Consolidated service definitions for networking
output "service_definitions" {
  description = "Service definitions for all services"
  value = [
    module.actualbudget.service_definition,
    module.affine.service_definition,
    module.calibre.service_definition,
    module.emulatorjs.service_definition,
    module.linkwarden.service_definition,
    module.ntfy.service_definition,
    module.pterodactyl_wings.service_definition,
    module.pterodactyl_panel.service_definition,
    module.n8n.service_definition,
    module.searxng.service_definition
  ]
}

output "homelab_docker_network_name" {
  description = "The name of the Docker network"
  value       = module.homelab_docker_network.name
}
