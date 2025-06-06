// Network environment
// Contains configurations for network infrastructure

locals {
  module_dir = "../../modules"
}

module "cloudflare_globals" {
  source = "${local.module_dir}/00-globals/cloudflare"
  
  cloudflare_api_token  = var.cloudflare_api_token
  cloudflare_account_id = var.cloudflare_account_id
  cloudflare_zone_id    = var.cloudflare_zone_id
  domain                = var.domain
}

module "homelab_docker_network" {
  source = "${local.module_dir}/01-networking/docker-network"
  
  name         = "homelab-network"
  driver       = "bridge"
  attachable   = true
  subnet       = "10.100.0.0/16"
}

module "homelab_cloudflared_tunnel" {
  source = "${local.module_dir}/01-networking/cloudflared-tunnel"
  
  cloudflare_account_id = module.cloudflare_globals.cloudflare_account_id
  cloudflare_zone_id    = module.cloudflare_globals.cloudflare_zone_id
  
  tunnel_name    = "homelab"
  container_name = "cloudflared-homelab"
  
  ingress_rules = [
    {
      hostname = "budget.${var.domain}"
      service  = "http://actualbudget:5006"
    },
  ]

  networks = [module.homelab_docker_network.name]
  
  monitoring = true
}
