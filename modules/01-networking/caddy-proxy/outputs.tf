output "container_name" {
  description = "The name of the deployed Caddy container"
  value       = module.caddy.container_name
}

output "config_hash" {
  description = "The SHA256 hash of the generated Caddyfile content"
  value       = sha256(local.caddyfile_content)
}

output "service_sites" {
  description = "Map of generated Caddy site configurations"
  value = {
    for site in local.caddy_site_configs : site.site_address => site.endpoint
  }
}
