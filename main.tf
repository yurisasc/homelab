module "system_globals" {
  source = "./modules/00-globals/system"
}

module "cloudflare_globals" {
  source = "./modules/00-globals/cloudflare"
}

module "tls_globals" {
  source = "./modules/00-globals/tls"
}

module "watchtower" {
  source = "./modules/20-services-apps/watchtower"
}

// Application services
module "services" {
  source = "./services"
}

locals {
  volume_host = "${module.system_globals.volume_host}/appdata"
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

module "homelab_caddy_proxy" {
  source = "./modules/01-networking/caddy-proxy"

  domain              = module.cloudflare_globals.domain
  tls_email           = module.tls_globals.tls_email
  container_name      = "caddy-proxy"
  cloudflare_zone_id  = module.cloudflare_globals.cloudflare_zone_id
  external_ip         = module.cloudflare_globals.external_ip
  service_definitions = module.services.service_definitions
  volume_path         = local.volume_host
  networks            = [module.services.homelab_docker_network_name]
  monitoring          = true

  # On-demand TLS for Dokploy-managed domains
  enable_ondemand_tls      = true
  ask_endpoint_url         = module.services.caddy_ask_endpoint
  dokploy_traefik_endpoint = module.services.dokploy_traefik_endpoint
}
