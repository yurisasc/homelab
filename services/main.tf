locals {
  module_dir = "../modules"
  data_dir   = module.system_globals.data_dir
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
  volume_path = "${local.data_dir}/actual"
  networks    = [module.homelab_docker_network.name]
}

module "emulatorjs" {
  source      = "${local.module_dir}/20-services-apps/emulatorjs"
  volume_path = "${local.data_dir}/emulatorjs"
}
