terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

module "smtp" {
  source = "../../../00-globals/smtp"
}

variable "image_tag" {
  description = "The tag for the Pterodactyl Panel container image"
  type        = string
  default     = "latest"
}

variable "volume_path" {
  description = "Base directory for volumes"
  type        = string
}

variable "networks" {
  description = "List of networks to which the container should be attached"
  type        = list(string)
  default     = []
}

variable "backup_networks" {
  description = "List of networks for backup access to database"
  type        = list(string)
  default     = []
}

locals {
  container_name = "pterodactyl-panel"
  database_name  = "pterodactyl-db"
  cache_name     = "pterodactyl-cache"
  panel_image    = "ghcr.io/pterodactyl/panel"
  database_image = "mariadb"
  cache_image    = "redis"
  panel_tag      = var.image_tag != "" ? var.image_tag : "latest"
  database_tag   = "10.5"
  cache_tag      = "alpine"
  env_file       = "${path.module}/.env"

  # Volume paths
  panel_volumes = [
    {
      host_path      = "${var.volume_path}/var"
      container_path = "/app/var"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/nginx"
      container_path = "/etc/nginx/http.d"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/certs"
      container_path = "/etc/letsencrypt"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/logs"
      container_path = "/app/storage/logs"
      read_only      = false
    }
  ]

  database_volumes = [
    {
      host_path      = "${var.volume_path}/database"
      container_path = "/var/lib/mysql"
      read_only      = false
    }
  ]

  # Environment variables
  panel_env_vars = {
    APP_URL                  = provider::dotenv::get_by_key("APP_URL", local.env_file)
    APP_TIMEZONE             = provider::dotenv::get_by_key("APP_TIMEZONE", local.env_file)
    APP_SERVICE_AUTHOR       = provider::dotenv::get_by_key("APP_SERVICE_AUTHOR", local.env_file)
    APP_CORS_ALLOWED_ORIGINS = provider::dotenv::get_by_key("APP_CORS_ALLOWED_ORIGINS", local.env_file)
    TRUSTED_PROXIES          = provider::dotenv::get_by_key("TRUSTED_PROXIES", local.env_file)
    MAIL_FROM                = module.smtp.mail_from
    MAIL_DRIVER              = "smtp"
    MAIL_HOST                = module.smtp.mail_host
    MAIL_PORT                = module.smtp.mail_port
    MAIL_USERNAME            = module.smtp.mail_username
    MAIL_PASSWORD            = module.smtp.mail_password
    MAIL_ENCRYPTION          = "false"
    DB_PASSWORD              = provider::dotenv::get_by_key("MYSQL_PASSWORD", local.env_file)
    APP_ENV                  = "production"
    APP_ENVIRONMENT_ONLY     = "false"
    CACHE_DRIVER             = "redis"
    SESSION_DRIVER           = "redis"
    QUEUE_DRIVER             = "redis"
    REDIS_HOST               = local.cache_name
    DB_HOST                  = local.database_name
    DB_PORT                  = "3306"
    DB_DATABASE              = provider::dotenv::get_by_key("MYSQL_DATABASE", local.env_file)
    DB_USERNAME              = provider::dotenv::get_by_key("MYSQL_USER", local.env_file)
  }

  database_env_vars = {
    MYSQL_PASSWORD      = provider::dotenv::get_by_key("MYSQL_PASSWORD", local.env_file)
    MYSQL_ROOT_PASSWORD = provider::dotenv::get_by_key("MYSQL_ROOT_PASSWORD", local.env_file)
    MYSQL_DATABASE      = provider::dotenv::get_by_key("MYSQL_DATABASE", local.env_file)
    MYSQL_USER          = provider::dotenv::get_by_key("MYSQL_USER", local.env_file)
  }
}

# Create a dedicated network for Pterodactyl
module "pterodactyl_network" {
  source     = "../../../01-networking/docker-network"
  name       = "ptero-panel"
  driver     = "bridge"
  subnet     = "172.20.0.0/16"
  attachable = true
}

# Database container
module "database" {
  source         = "../../../10-services-generic/docker-service"
  container_name = local.database_name
  image          = local.database_image
  tag            = local.database_tag
  volumes        = local.database_volumes
  env_vars       = local.database_env_vars
  networks       = concat([module.pterodactyl_network.name], var.backup_networks)
  command        = ["--default-authentication-plugin=mysql_native_password"]
}

# Cache container
module "cache" {
  source         = "../../../10-services-generic/docker-service"
  container_name = local.cache_name
  image          = local.cache_image
  tag            = local.cache_tag
  networks       = [module.pterodactyl_network.name]
}

# Panel container
module "panel" {
  source         = "../../../10-services-generic/docker-service"
  container_name = local.container_name
  image          = local.panel_image
  tag            = local.panel_tag
  volumes        = local.panel_volumes
  env_vars       = local.panel_env_vars
  networks       = concat([module.pterodactyl_network.name], var.networks)
  depends_on     = [module.database, module.cache]
}

output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = 80
    endpoint     = "http://${local.container_name}:80"
    subdomains   = ["gameservers"]
    publish_via  = "tunnel"
  }
}

output "db_backup_config" {
  description = "Database backup configuration for Pterodactyl Panel"
  value = {
    name         = "pterodactyl"
    type         = "mysql"
    host         = local.database_name
    port         = 3306
    database     = provider::dotenv::get_by_key("MYSQL_DATABASE", local.env_file)
    username     = provider::dotenv::get_by_key("MYSQL_USER", local.env_file)
    password_env = "MYSQL_PASSWORD"  # Env var name in Pterodactyl .env
    env_file     = local.env_file     # Path to Pterodactyl .env file
  }
}
