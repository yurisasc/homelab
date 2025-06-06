// Application services environment
// Contains configurations for all application services

// Import global Terraform settings
terraform {
  # Include backend configuration if needed
  # backend "local" { ... }
}

locals {
  module_dir = "../../modules"
}

module "actualbudget" {
  source = "${local.module_dir}/20-services-apps/actualbudget"
  
  container_name    = "actualbudget"
  timezone          = var.timezone
  data_volume_path  = "${var.data_dir}/actual/data"
  port              = var.actualbudget_port
  networks          = var.default_networks
}

module "emulatorjs" {
  source = "${local.module_dir}/20-services-apps/emulatorjs"
  
  container_name     = "emulatorjs"
  timezone           = var.timezone
  puid               = var.puid
  pgid               = var.pgid
  config_volume_path = "${var.data_dir}/emulatorjs/config"
  data_volume_path   = "${var.data_dir}/emulatorjs/data"
  frontend_port      = var.emulatorjs_frontend_port
  config_port        = var.emulatorjs_config_port
  backend_port       = var.emulatorjs_backend_port
}
