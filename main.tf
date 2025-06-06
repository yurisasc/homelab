// Root module that orchestrates all environments
// This unified approach keeps a single entry point while organizing by function

// Network infrastructure
module "network" {
  source = "./environments/network"

  // Cloudflare variables
  cloudflare_api_token  = var.cloudflare_api_token
  cloudflare_account_id = var.cloudflare_account_id
  cloudflare_zone_id    = var.cloudflare_zone_id
  domain                = var.domain
}

// Core infrastructure (monitoring, globals)
module "core" {
  source = "./environments/core"

  depends_on = [module.network]
  
  timezone = var.timezone
  
  // Watchtower variables
  watchtower_enable_notifications = var.watchtower_enable_notifications
  watchtower_notification_url     = var.watchtower_notification_url
}

// Application services
module "services" {
  source = "./environments/services"

  depends_on = [module.core, module.network]
  
  timezone = var.timezone
  puid     = var.puid
  pgid     = var.pgid
  data_dir = var.data_dir
  
  // ActualBudget variables
  actualbudget_port      = var.actualbudget_port
  
  // EmulatorJS variables
  emulatorjs_frontend_port = var.emulatorjs_frontend_port
  emulatorjs_config_port   = var.emulatorjs_config_port
  emulatorjs_backend_port  = var.emulatorjs_backend_port

  // Docker network variables
  default_networks = [module.network.homelab_docker_network_name]
}
