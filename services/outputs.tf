// Services environment outputs

// Consolidated service definitions for networking
output "service_definitions" {
  description = "Service definitions for all services"
  value = [
    module.actualbudget.service_definition,
    module.affine.service_definition,
    module.arr.service_definition,
    module.calibre.service_definition,
    module.copyparty.service_definition,
    module.crawl4ai.service_definition,
    module.dify.service_definition,
    module.dokploy.service_definition,
    module.emulatorjs.service_definition,
    module.fossflow.service_definition,
    module.glance.service_definition,
    module.immich.service_definition,
    module.jellyfin.service_definition,
    module.linkwarden.service_definition,
    module.n8n.service_definition,
    module.n8n.n8n_mcp_service_definition,
    module.nocodb.service_definition,
    module.ntfy.service_definition,
    module.portainer.service_definition,
    module.pterodactyl_wings.service_definition,
    module.pterodactyl_panel.service_definition,
    module.qbittorrent.service_definition,
    module.sabnzbd.service_definition,
    module.searxng.service_definition
  ]
}

output "dokploy_traefik_endpoint" {
  description = "Internal Traefik endpoint for Dokploy on-demand TLS routing"
  value       = module.dokploy.traefik_endpoint
}

output "dokploy_network_name" {
  description = "Name of the Dokploy internal network"
  value       = module.dokploy.dokploy_network_name
}

output "caddy_ask_endpoint" {
  description = "Internal endpoint for the Caddy on-demand TLS ask service"
  value       = module.caddy_ask_service.endpoint
}

output "homelab_docker_network_name" {
  description = "The name of the Docker network"
  value       = module.homelab_docker_network.name
}

output "db_backup_configs" {
  description = "Aggregated database backup configurations from all services"
  value = [
    for cfg in [
      try(module.immich.db_backup_config, null),
      try(module.dify.db_backup_config, null),
      try(module.linkwarden.db_backup_config, null),
      try(module.nocodb.db_backup_config, null),
      try(module.affine.db_backup_config, null),
      try(module.n8n.db_backup_config, null),
      try(module.dokploy.db_backup_config, null),
      try(module.pterodactyl_panel.db_backup_config, null),
    ] : cfg if cfg != null
  ]
}
