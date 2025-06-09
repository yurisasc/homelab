module "coolify_caddy" {
  source         = "../../10-services-generic/caddy-proxy"
  container_name = "coolify-caddy"
  volume_path    = "${var.volume_path}/caddy"
  networks       = concat([module.coolify_network.name], var.networks)
  
  # Use custom ports (not exposing 80/443 directly)
  http_port      = 7080
  https_port     = 6443
  admin_port     = 7081
  
  sites = [
    {
      domain = "deploy.yuris.dev"
      routes = [
        {
          path        = "/app/*"     # Main WebSocket endpoint for Pusher/Soketi
          target_host = local.soketi_container_name
          target_port = local.soketi_port
          websocket   = true
        },
        {
          path        = "/apps/*"    # Alternative WebSocket endpoint
          target_host = local.soketi_container_name
          target_port = local.soketi_port
          websocket   = true
        },
        {
          path        = "/*"         # All other requests go to the main app
          target_host = local.app_container_name
          target_port = local.app_port
          websocket   = false
        }
      ]
    }
  ]
}
