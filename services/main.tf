locals {
  module_dir  = "../modules"
  root_volume = module.system_globals.volume_host
  volume_host = "${module.system_globals.volume_host}/appdata"
  data_host   = "${module.system_globals.volume_host}/data"
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

// Docker network used for media services
module "media_docker_network" {
  source = "${local.module_dir}/01-networking/docker-network"

  name       = "media-network"
  driver     = "bridge"
  attachable = true
  subnet     = "10.110.0.0/16"
}

module "actualbudget" {
  source      = "${local.module_dir}/20-services-apps/actualbudget"
  volume_path = "${local.volume_host}/actual"
  networks    = [module.homelab_docker_network.name]
  image_tag   = "25.12.0-alpine"
}

module "affine" {
  source      = "${local.module_dir}/20-services-apps/affine"
  volume_path = "${local.volume_host}/affine"
  networks    = [module.homelab_docker_network.name]
  image_tag   = "canary-2430bb4"
}

module "arr" {
  source         = "${local.module_dir}/20-services-apps/arr"
  volume_path    = "${local.volume_host}/arr"
  data_path      = local.data_host
  downloads_path = "${local.data_host}/torrents"
  networks       = [module.media_docker_network.name]
  proxy_networks = [module.homelab_docker_network.name]
  qbittorrent_host = "gluetun"
}

module "calibre" {
  source      = "${local.module_dir}/20-services-apps/calibre"
  volume_path = "${local.volume_host}/calibre"
  networks    = [module.homelab_docker_network.name]
  image_tag   = "V3.1.4"
}

module "copyparty" {
  source         = "${local.module_dir}/20-services-apps/copyparty"
  fileshare_path = local.root_volume
  config_path    = "${local.volume_host}/copyparty"
  networks       = [module.homelab_docker_network.name]
  image_tag      = "1.19.23"
}

module "crawl4ai" {
  source      = "${local.module_dir}/20-services-apps/crawl4ai"
  volume_path = "${local.volume_host}/crawl4ai"
  networks    = [module.homelab_docker_network.name]
  image_tag   = "0.7.8"
}

module "emulatorjs" {
  source      = "${local.module_dir}/20-services-apps/emulatorjs"
  volume_path = "${local.volume_host}/emulatorjs"
  image_tag   = "1.9.2"
}

module "glance" {
  source      = "${local.module_dir}/20-services-apps/glance"
  volume_path = "${local.volume_host}/glance"
  networks    = [module.homelab_docker_network.name]
  image_tag   = "v0.8.4"
}

module "gluetun" {
  source      = "${local.module_dir}/20-services-apps/gluetun"
  volume_path = "${local.volume_host}/gluetun"
  networks    = [module.media_docker_network.name]
  ports       = [
    # Expose qBittorrent UI to the host
    {
      internal = 8080
      external = 8080
      protocol = "tcp"
    }
  ]
  image_tag   = "v3.40.3"
}

module "immich" {
  source       = "${local.module_dir}/20-services-apps/immich"
  appdata_path = "${local.volume_host}/immich"
  library_path = "${local.data_host}/media/photos"
  networks     = [module.homelab_docker_network.name]
  image_tag    = "v2.4.1"
}

module "jellyfin" {
  source      = "${local.module_dir}/20-services-apps/jellyfin"
  volume_path = "${local.volume_host}/jellyfin"
  data_path   = "${local.data_host}"
  networks    = [module.media_docker_network.name, module.homelab_docker_network.name]
  image_tag   = "10.11.5"
}

module "linkwarden" {
  source      = "${local.module_dir}/20-services-apps/linkwarden"
  volume_path = "${local.volume_host}/linkwarden"
  networks    = [module.homelab_docker_network.name]
  image_tag   = "v2.13.2"
}

module "n8n" {
  source      = "${local.module_dir}/20-services-apps/n8n"
  volume_path = "${local.volume_host}/n8n"
  networks    = [module.homelab_docker_network.name]
  image_tag   = "2.0.3"
}

module "nocodb" {
  source      = "${local.module_dir}/20-services-apps/nocodb"
  volume_path = "${local.volume_host}/nocodb"
  networks    = [module.homelab_docker_network.name]
  image_tag   = "0.265.1"
}

module "ntfy" {
  source      = "${local.module_dir}/20-services-apps/ntfy"
  volume_path = "${local.volume_host}/ntfy"
  networks    = [module.homelab_docker_network.name]
  image_tag   = "v2.15.0"
}

module "portainer" {
  source      = "${local.module_dir}/20-services-apps/portainer"
  volume_path = "${local.volume_host}/portainer"
  networks    = [module.homelab_docker_network.name]
  image_tag   = "2.33.6-alpine"
}

module "pterodactyl_panel" {
  source      = "${local.module_dir}/20-services-apps/pterodactyl/panel"
  volume_path = "${local.volume_host}/pterodactyl/panel"
  networks    = [module.homelab_docker_network.name]
  image_tag   = "v1.11.11"
}

module "pterodactyl_wings" {
  source      = "${local.module_dir}/20-services-apps/pterodactyl/wings"
  volume_path = "${local.volume_host}/pterodactyl/wings"
  networks    = [module.homelab_docker_network.name]
  image_tag   = "v1.11.13"
}

module "qbittorrent" {
  source         = "${local.module_dir}/20-services-apps/qbittorrent"
  volume_path    = "${local.volume_host}/qbittorrent"
  downloads_path = "${local.data_host}/torrents"
  networks               = [module.media_docker_network.name]
  connect_via_gluetun    = true
  gluetun_container_name = "gluetun"
  depends_on             = [module.gluetun]
  image_tag              = "5.1.4"
}

module "sabnzbd" {
  source         = "${local.module_dir}/20-services-apps/sabnzbd"
  volume_path    = "${local.volume_host}/sabnzbd"
  downloads_path = "${local.data_host}/usenet/downloads"
  networks       = [module.media_docker_network.name, module.homelab_docker_network.name]
  image_tag      = "4.5.5"
}

module "searxng" {
  source      = "${local.module_dir}/20-services-apps/searxng"
  volume_path = "${local.volume_host}/searxng"
  networks    = [module.homelab_docker_network.name]
  image_tag   = "2025.12.19-8bf600cc6"
}
