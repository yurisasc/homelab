// Core infrastructure components
// These are the foundational services that other services depend on

locals {
  module_dir = "../../modules"
}

// Core monitoring and maintenance service
module "watchtower" {
  source = "${local.module_dir}/20-services-apps/watchtower"
  
  timezone             = var.timezone
  poll_interval        = 86400
  cleanup              = true
  enable_notifications = var.watchtower_enable_notifications
  notification_url     = var.watchtower_notification_url
}
