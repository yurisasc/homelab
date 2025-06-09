terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

variable "image_tag" {
  description = "The tag for the coolify container image"
  type        = string
  default     = "latest"
}

variable "volume_path" {
  description = "Base directory for volumes"
  type        = string
}

variable "networks" {
  description = "List of networks to which the coolify container should be attached"
  type        = list(string)
  default     = []
}

locals {
  env_file = "${path.module}/.env"

  # Container names
  app_container_name    = "coolify"
  db_container_name     = "coolify-db"
  redis_container_name  = "coolify-redis"
  soketi_container_name = "coolify-realtime"

  # Images and tags
  app_image    = "ghcr.io/coollabsio/coolify"
  db_image     = "postgres"
  redis_image  = "redis"
  soketi_image = "ghcr.io/coollabsio/coolify-realtime"

  app_tag    = var.image_tag != "" ? var.image_tag : "latest"
  db_tag     = "15-alpine"
  redis_tag  = "7-alpine"
  soketi_tag = "1.0.8"

  monitoring  = true
  app_port    = 8080
  soketi_port = 6001

  # Volume mappings
  app_volumes = [
    {
      host_path      = "${var.volume_path}/source/.env"
      container_path = "/var/www/html/.env"
      read_only      = true
    },
    {
      host_path      = "${var.volume_path}/ssh"
      container_path = "/var/www/html/storage/app/ssh"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/applications"
      container_path = "/var/www/html/storage/app/applications"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/databases"
      container_path = "/var/www/html/storage/app/databases"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/services"
      container_path = "/var/www/html/storage/app/services"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/backups"
      container_path = "/var/www/html/storage/app/backups"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/webhooks-during-maintenance"
      container_path = "/var/www/html/storage/app/webhooks-during-maintenance"
      read_only      = false
    }
  ]

  db_volumes = [
    {
      host_path      = "${var.volume_path}/db_data"
      container_path = "/var/lib/postgresql/data"
      read_only      = false
    }
  ]

  redis_volumes = [
    {
      host_path      = "${var.volume_path}/redis_data"
      container_path = "/data"
      read_only      = false
    }
  ]

  soketi_volumes = [
    {
      host_path      = "${var.volume_path}/ssh"
      container_path = "/var/www/html/storage/app/ssh"
      read_only      = false
    }
  ]

  app_env_vars = {
    APP_ENV                      = "production"
    APP_ID                       = provider::dotenv::get_by_key("APP_ID", local.env_file)
    APP_NAME                     = provider::dotenv::get_by_key("APP_NAME", local.env_file)
    APP_KEY                      = provider::dotenv::get_by_key("APP_KEY", local.env_file)
    ROOT_USERNAME                = provider::dotenv::get_by_key("ROOT_USERNAME", local.env_file)
    ROOT_USER_EMAIL              = provider::dotenv::get_by_key("ROOT_USER_EMAIL", local.env_file)
    ROOT_USER_PASSWORD           = provider::dotenv::get_by_key("ROOT_USER_PASSWORD", local.env_file)
    PHP_MEMORY_LIMIT             = provider::dotenv::get_by_key("PHP_MEMORY_LIMIT", local.env_file)
    PHP_FPM_PM_CONTROL           = provider::dotenv::get_by_key("PHP_FPM_PM_CONTROL", local.env_file)
    PHP_FPM_PM_START_SERVERS     = provider::dotenv::get_by_key("PHP_FPM_PM_START_SERVERS", local.env_file)
    PHP_FPM_PM_MIN_SPARE_SERVERS = provider::dotenv::get_by_key("PHP_FPM_PM_MIN_SPARE_SERVERS", local.env_file)
    PHP_FPM_PM_MAX_SPARE_SERVERS = provider::dotenv::get_by_key("PHP_FPM_PM_MAX_SPARE_SERVERS", local.env_file)
    DB_DATABASE                  = provider::dotenv::get_by_key("DB_DATABASE", local.env_file)
    DB_USERNAME                  = provider::dotenv::get_by_key("DB_USERNAME", local.env_file)
    DB_PASSWORD                  = provider::dotenv::get_by_key("DB_PASSWORD", local.env_file)
    REDIS_PASSWORD               = provider::dotenv::get_by_key("REDIS_PASSWORD", local.env_file)
  }

  db_env_vars = {
    POSTGRES_USER     = provider::dotenv::get_by_key("DB_USERNAME", local.env_file)
    POSTGRES_PASSWORD = provider::dotenv::get_by_key("DB_PASSWORD", local.env_file)
    POSTGRES_DB       = provider::dotenv::get_by_key("DB_DATABASE", local.env_file)
  }

  redis_env_vars = {
    REDIS_PASSWORD = provider::dotenv::get_by_key("REDIS_PASSWORD", local.env_file)
  }

  soketi_env_vars = {
    APP_NAME                  = provider::dotenv::get_by_key("APP_NAME", local.env_file)
    SOKETI_DEBUG              = provider::dotenv::get_by_key("SOKETI_DEBUG", local.env_file)
    SOKETI_DEFAULT_APP_ID     = provider::dotenv::get_by_key("PUSHER_APP_ID", local.env_file)
    SOKETI_DEFAULT_APP_KEY    = provider::dotenv::get_by_key("PUSHER_APP_KEY", local.env_file)
    SOKETI_DEFAULT_APP_SECRET = provider::dotenv::get_by_key("PUSHER_APP_SECRET", local.env_file)
  }

  healthchecks = {
    db = {
      test     = ["CMD-SHELL", "pg_isready -U coolify -d coolify"]
      interval = "5s"
      timeout  = "2s"
      retries  = 10
    }

    redis = {
      test     = ["CMD", "redis-cli", "ping"]
      interval = "5s"
      timeout  = "2s"
      retries  = 10
    }

    soketi = {
      test     = ["CMD-SHELL", "wget -qO- http://127.0.0.1:6001/ready && wget -qO- http://127.0.0.1:6002/ready || exit 1"]
      interval = "5s"
      timeout  = "2s"
      retries  = 10
    }

    app = {
      test     = ["CMD-SHELL", "curl --fail http://127.0.0.1:8080/api/health || exit 1"]
      interval = "5s"
      timeout  = "2s"
      retries  = 10
    }
  }
}

module "coolify_network" {
  source = "../../01-networking/docker-network"
  name   = "coolify"
  driver = "bridge"
}

module "postgres" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.db_container_name
  image          = local.db_image
  tag            = local.db_tag
  volumes        = local.db_volumes
  puid           = 9999
  pgid           = 9999
  env_vars       = local.db_env_vars
  networks       = [module.coolify_network.name]
  monitoring     = local.monitoring
  healthcheck    = local.healthchecks.db
}

module "redis" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.redis_container_name
  image          = local.redis_image
  tag            = local.redis_tag
  volumes        = local.redis_volumes
  puid           = 9999
  pgid           = 9999
  env_vars       = local.redis_env_vars
  networks       = [module.coolify_network.name]
  monitoring     = local.monitoring
  command        = ["redis-server", "--save", "20", "1", "--loglevel", "warning", "--requirepass", provider::dotenv::get_by_key("REDIS_PASSWORD", local.env_file)]
  healthcheck    = local.healthchecks.redis
}

module "soketi" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.soketi_container_name
  image          = local.soketi_image
  tag            = local.soketi_tag
  volumes        = local.soketi_volumes
  puid           = 9999
  pgid           = 9999
  env_vars       = local.soketi_env_vars
  networks       = [module.coolify_network.name]
  monitoring     = local.monitoring
  healthcheck    = local.healthchecks.soketi
}

module "coolify" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.app_container_name
  image          = local.app_image
  tag            = local.app_tag
  volumes        = local.app_volumes
  puid           = 9999
  pgid           = 9999
  env_vars       = local.app_env_vars
  networks       = concat([module.coolify_network.name], var.networks)
  monitoring     = local.monitoring
  healthcheck    = local.healthchecks.app
  host_mappings  = [
    {
      host = "host.docker.internal"
      ip   = "host-gateway"
    }
  ]
  
  depends_on     = [module.postgres, module.redis, module.soketi]
}

output "service_definition" {
  description = "Service definition with ingress configuration"
  value = {
    name         = local.app_container_name
    primary_port = local.app_port
    endpoint     = "http://${local.app_container_name}:${local.app_port}"
    subdomains   = ["deploy"]
  }
}
