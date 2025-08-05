locals {
  module_dir  = "../modules"
  volume_host = module.system_globals.volume_host
}

module "system_globals" {
  source = "${local.module_dir}/00-globals/system"
}

// Docker network used for modules that needs to be exposed to the internet
// using Cloudflared
module "homelab_docker_network" {
  source = "${local.module_dir}/01-networking/docker-network"

  name       = "homelab-network"
  driver     = "bridge"
  attachable = true
  subnet     = "10.100.0.0/16"
}

module "actualbudget" {
  source      = "${local.module_dir}/20-services-apps/actualbudget"
  volume_path = "${local.volume_host}/actual"
  networks    = [module.homelab_docker_network.name]
}

module "affine" {
  source      = "${local.module_dir}/20-services-apps/affine"
  volume_path = "${local.volume_host}/affine"
  networks    = [module.homelab_docker_network.name]
}

module "calibre" {
  source      = "${local.module_dir}/20-services-apps/calibre"
  volume_path = "${local.volume_host}/calibre"
  networks    = [module.homelab_docker_network.name]
}

module "crawl4ai" {
  source      = "${local.module_dir}/20-services-apps/crawl4ai"
  volume_path = "${local.volume_host}/crawl4ai"
  networks    = [module.homelab_docker_network.name]
}

module "emulatorjs" {
  source      = "${local.module_dir}/20-services-apps/emulatorjs"
  volume_path = "${local.volume_host}/emulatorjs"
}

module "glance" {
  source      = "${local.module_dir}/20-services-apps/glance"
  volume_path = "${local.volume_host}/glance"
  networks    = [module.homelab_docker_network.name]
}

module "linkwarden" {
  source      = "${local.module_dir}/20-services-apps/linkwarden"
  volume_path = "${local.volume_host}/linkwarden"
  networks    = [module.homelab_docker_network.name]
}

module "n8n" {
  source      = "${local.module_dir}/20-services-apps/n8n"
  volume_path = "${local.volume_host}/n8n"
  networks    = [module.homelab_docker_network.name]
}

module "nocodb" {
  source      = "${local.module_dir}/20-services-apps/nocodb"
  volume_path = "${local.volume_host}/nocodb"
  networks    = [module.homelab_docker_network.name]
}

module "ntfy" {
  source      = "${local.module_dir}/20-services-apps/ntfy"
  volume_path = "${local.volume_host}/ntfy"
  networks    = [module.homelab_docker_network.name]
}

module "portainer" {
  source      = "${local.module_dir}/20-services-apps/portainer"
  volume_path = "${local.volume_host}/portainer"
  networks    = [module.homelab_docker_network.name]
}

module "pterodactyl_panel" {
  source      = "${local.module_dir}/20-services-apps/pterodactyl/panel"
  volume_path = "${local.volume_host}/pterodactyl/panel"
  networks    = [module.homelab_docker_network.name]
}

module "pterodactyl_wings" {
  source      = "${local.module_dir}/20-services-apps/pterodactyl/wings"
  volume_path = "${local.volume_host}/pterodactyl/wings"
  networks    = [module.homelab_docker_network.name]
}

module "searxng" {
  source      = "${local.module_dir}/20-services-apps/searxng"
  volume_path = "${local.volume_host}/searxng"
  networks    = [module.homelab_docker_network.name]
}
