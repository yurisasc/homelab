module "cloudflare_globals" {
  source = "./modules/00-globals/cloudflare"
}

module "watchtower" {
  source = "./modules/20-services-apps/watchtower"
}

// Application services
module "services" {
  source = "./services"
}

module "homelab_cloudflared_tunnel" {
  source                = "./modules/01-networking/cloudflared-tunnel"
  cloudflare_account_id = module.cloudflare_globals.cloudflare_account_id
  cloudflare_zone_id    = module.cloudflare_globals.cloudflare_zone_id
  domain                = module.cloudflare_globals.domain
  tunnel_name           = "homelab"
  container_name        = "cloudflared-homelab"
  service_definitions   = module.services.service_definitions
  networks              = [module.services.homelab_docker_network_name]
  monitoring            = true
}
