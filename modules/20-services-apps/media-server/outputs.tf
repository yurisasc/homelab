output "service_definitions" {
  description = "Service definitions for integration with networking modules"
  value = [
    module.jellyfin.service_definition,
    module.jellyseerr.service_definition,
    module.sabnzbd.service_definition
  ]
}

output "network_name" {
  description = "Name of the media server network"
  value       = module.media_server_network.name
}
