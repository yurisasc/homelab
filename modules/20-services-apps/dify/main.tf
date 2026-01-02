terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

variable "image_tag" {
  description = "The tag for the Dify container images"
  type        = string
  default     = "1.11.2"
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

variable "subdomain" {
  description = "The subdomain to use for the Dify service"
  type        = string
  default     = "dify"
}

module "system_globals" {
  source = "../../00-globals/system"
}

module "smtp" {
  source = "../../00-globals/smtp"
}

module "cloudflare_globals" {
  source = "../../00-globals/cloudflare"
}

locals {
  # Container names
  api_name           = "dify-api"
  worker_name        = "dify-worker"
  worker_beat_name   = "dify-worker-beat"
  web_name           = "dify-web"
  postgres_name      = "dify-postgres"
  redis_name         = "dify-redis"
  sandbox_name       = "dify-sandbox"
  ssrf_proxy_name    = "dify-ssrf-proxy"
  weaviate_name      = "dify-weaviate"
  plugin_daemon_name = "dify-plugin-daemon"

  # Images
  api_image           = "langgenius/dify-api"
  web_image           = "langgenius/dify-web"
  postgres_image      = "postgres"
  redis_image         = "redis"
  sandbox_image       = "langgenius/dify-sandbox"
  ssrf_proxy_image    = "ubuntu/squid"
  weaviate_image      = "semitechnologies/weaviate"
  plugin_daemon_image = "langgenius/dify-plugin-daemon"

  # Tags
  api_tag           = var.image_tag
  web_tag           = var.image_tag
  postgres_tag      = "15-alpine"
  redis_tag         = "6-alpine"
  sandbox_tag       = "0.2.12"
  ssrf_proxy_tag    = "latest"
  weaviate_tag      = "1.27.0"
  plugin_daemon_tag = "0.5.2-local"

  monitoring       = true
  env_file         = "${path.module}/.env"
  web_port         = 3000
  api_port         = 5001
  plugin_debug_port = 5003

  public_base_url = "https://${var.subdomain}.${module.cloudflare_globals.domain}"

  # Secrets from .env
  secret_key         = provider::dotenv::get_by_key("DIFY_SECRET_KEY", local.env_file)
  db_password        = provider::dotenv::get_by_key("DIFY_DB_PASSWORD", local.env_file)
  redis_password     = provider::dotenv::get_by_key("DIFY_REDIS_PASSWORD", local.env_file)
  sandbox_api_key    = provider::dotenv::get_by_key("DIFY_SANDBOX_API_KEY", local.env_file)
  weaviate_api_key   = provider::dotenv::get_by_key("DIFY_WEAVIATE_API_KEY", local.env_file)
  plugin_daemon_key  = provider::dotenv::get_by_key("DIFY_PLUGIN_DAEMON_KEY", local.env_file)
  plugin_inner_api_key = provider::dotenv::get_by_key("DIFY_PLUGIN_INNER_API_KEY", local.env_file)

  # Shared environment variables for API and Worker
  shared_api_worker_env = {
    CONSOLE_WEB_URL = local.public_base_url
    CONSOLE_API_URL = local.public_base_url
    SERVICE_API_URL = local.public_base_url
    APP_WEB_URL     = local.public_base_url
    APP_API_URL     = local.public_base_url
    FILES_URL       = local.public_base_url

    # Core settings
    SECRET_KEY        = local.secret_key
    DEPLOY_ENV        = "PRODUCTION"
    LOG_LEVEL         = "INFO"
    MIGRATION_ENABLED = "true"

    # Database
    DB_USERNAME = "postgres"
    DB_PASSWORD = local.db_password
    DB_HOST     = local.postgres_name
    DB_PORT     = "5432"
    DB_DATABASE = "dify"

    # Redis
    REDIS_HOST     = local.redis_name
    REDIS_PORT     = "6379"
    REDIS_PASSWORD = local.redis_password
    REDIS_DB       = "0"

    # Celery
    CELERY_BROKER_URL = "redis://:${local.redis_password}@${local.redis_name}:6379/1"

    # Vector store (Weaviate)
    VECTOR_STORE       = "weaviate"
    WEAVIATE_ENDPOINT  = "http://${local.weaviate_name}:8080"
    WEAVIATE_API_KEY   = local.weaviate_api_key

    # Code execution (Sandbox)
    CODE_EXECUTION_ENDPOINT = "http://${local.sandbox_name}:8194"
    CODE_EXECUTION_API_KEY  = local.sandbox_api_key

    # SSRF proxy
    SSRF_PROXY_HTTP_URL  = "http://${local.ssrf_proxy_name}:3128"
    SSRF_PROXY_HTTPS_URL = "http://${local.ssrf_proxy_name}:3128"

    # Plugin daemon
    PLUGIN_DAEMON_URL        = "http://${local.plugin_daemon_name}:5002"
    PLUGIN_DAEMON_KEY        = local.plugin_daemon_key
    INNER_API_KEY_FOR_PLUGIN = local.plugin_inner_api_key

    # Storage (local filesystem)
    STORAGE_TYPE    = "opendal"
    OPENDAL_SCHEME  = "fs"
    OPENDAL_FS_ROOT = "/app/api/storage"

    # Mail configuration (SMTP)
    MAIL_TYPE              = "smtp"
    SMTP_SERVER            = module.smtp.mail_host
    SMTP_PORT              = module.smtp.mail_port
    SMTP_USERNAME          = module.smtp.mail_username
    SMTP_PASSWORD          = module.smtp.mail_password
    SMTP_USE_TLS           = "true"
    MAIL_DEFAULT_SEND_FROM = module.smtp.mail_from
  }

  # Volumes
  app_storage_volumes = [
    {
      host_path      = "${var.volume_path}/storage"
      container_path = "/app/api/storage"
      read_only      = false
    }
  ]

  postgres_volumes = [
    {
      host_path      = "${var.volume_path}/db/data"
      container_path = "/var/lib/postgresql/data"
      read_only      = false
    }
  ]

  redis_volumes = [
    {
      host_path      = "${var.volume_path}/redis/data"
      container_path = "/data"
      read_only      = false
    }
  ]

  weaviate_volumes = [
    {
      host_path      = "${var.volume_path}/weaviate"
      container_path = "/var/lib/weaviate"
      read_only      = false
    }
  ]

  sandbox_volumes = [
    {
      host_path      = "${var.volume_path}/sandbox/dependencies"
      container_path = "/dependencies"
      read_only      = false
    }
  ]

  plugin_daemon_volumes = [
    {
      host_path      = "${var.volume_path}/plugin_daemon"
      container_path = "/app/storage"
      read_only      = false
    }
  ]

  # Healthchecks
  postgres_healthcheck = {
    test         = ["CMD", "pg_isready", "-h", "localhost", "-U", "postgres", "-d", "dify"]
    interval     = "5s"
    timeout      = "5s"
    retries      = 30
    start_period = "10s"
  }

  redis_healthcheck = {
    test         = ["CMD-SHELL", "redis-cli -a ${local.redis_password} ping | grep -q PONG"]
    interval     = "5s"
    timeout      = "5s"
    retries      = 10
    start_period = "5s"
  }

  weaviate_healthcheck = {
    test         = ["CMD", "wget", "-q", "--spider", "http://localhost:8080/v1/.well-known/ready"]
    interval     = "10s"
    timeout      = "5s"
    retries      = 10
    start_period = "10s"
  }

  sandbox_healthcheck = {
    test         = ["CMD", "curl", "-f", "http://localhost:8194/health"]
    interval     = "10s"
    timeout      = "5s"
    retries      = 10
    start_period = "10s"
  }
}

# Create internal network for Dify services
module "dify_network" {
  source = "../../01-networking/docker-network"
  name   = "dify-network"
  driver = "bridge"
  subnet = "172.30.0.0/16"
}

# Create a separate network for SSRF proxy isolation
module "dify_ssrf_network" {
  source = "../../01-networking/docker-network"
  name   = "dify-ssrf-network"
  driver = "bridge"
  subnet = "172.31.0.0/16"
}

# PostgreSQL database
module "postgres" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.postgres_name
  image          = local.postgres_image
  tag            = local.postgres_tag
  volumes        = local.postgres_volumes
  env_vars = {
    POSTGRES_USER     = "postgres"
    POSTGRES_PASSWORD = local.db_password
    POSTGRES_DB       = "dify"
    PGDATA            = "/var/lib/postgresql/data/pgdata"
  }
  networks    = concat([module.dify_network.name], var.backup_networks)
  monitoring  = local.monitoring
  healthcheck = local.postgres_healthcheck
}

# Redis cache
module "redis" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.redis_name
  image          = local.redis_image
  tag            = local.redis_tag
  volumes        = local.redis_volumes
  env_vars = {
    REDISCLI_AUTH = local.redis_password
  }
  command     = ["redis-server", "--requirepass", local.redis_password]
  networks    = [module.dify_network.name]
  monitoring  = local.monitoring
  healthcheck = local.redis_healthcheck
}

# Weaviate vector store
module "weaviate" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.weaviate_name
  image          = local.weaviate_image
  tag            = local.weaviate_tag
  volumes        = local.weaviate_volumes
  env_vars = {
    PERSISTENCE_DATA_PATH                  = "/var/lib/weaviate"
    QUERY_DEFAULTS_LIMIT                   = "25"
    AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED = "false"
    DEFAULT_VECTORIZER_MODULE              = "none"
    CLUSTER_HOSTNAME                       = "node1"
    AUTHENTICATION_APIKEY_ENABLED          = "true"
    AUTHENTICATION_APIKEY_ALLOWED_KEYS     = local.weaviate_api_key
    AUTHENTICATION_APIKEY_USERS            = "dify@localhost"
    AUTHORIZATION_ADMINLIST_ENABLED        = "true"
    AUTHORIZATION_ADMINLIST_USERS          = "dify@localhost"
    DISABLE_TELEMETRY                      = "true"
  }
  networks    = [module.dify_network.name]
  monitoring  = local.monitoring
  healthcheck = local.weaviate_healthcheck
}

# SSRF Proxy (Squid)
module "ssrf_proxy" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.ssrf_proxy_name
  image          = local.ssrf_proxy_image
  tag            = local.ssrf_proxy_tag
  env_vars = {
    HTTP_PORT    = "3128"
    COREDUMP_DIR = "/var/spool/squid"
  }
  networks   = [module.dify_network.name, module.dify_ssrf_network.name]
  monitoring = local.monitoring
}

# Sandbox for code execution
module "sandbox" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.sandbox_name
  image          = local.sandbox_image
  tag            = local.sandbox_tag
  volumes        = local.sandbox_volumes
  env_vars = {
    API_KEY        = local.sandbox_api_key
    GIN_MODE       = "release"
    WORKER_TIMEOUT = "15"
    ENABLE_NETWORK = "true"
    HTTP_PROXY     = "http://${local.ssrf_proxy_name}:3128"
    HTTPS_PROXY    = "http://${local.ssrf_proxy_name}:3128"
    SANDBOX_PORT   = "8194"
  }
  networks    = [module.dify_ssrf_network.name]
  monitoring  = local.monitoring
  healthcheck = local.sandbox_healthcheck
  depends_on  = [module.ssrf_proxy]
}

# Plugin daemon
module "plugin_daemon" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.plugin_daemon_name
  image          = local.plugin_daemon_image
  tag            = local.plugin_daemon_tag
  volumes        = local.plugin_daemon_volumes
  env_vars = merge(local.shared_api_worker_env, {
    DB_DATABASE                    = "dify_plugin"
    SERVER_PORT                    = "5002"
    SERVER_KEY                     = local.plugin_daemon_key
    MAX_PLUGIN_PACKAGE_SIZE        = "52428800"
    PPROF_ENABLED                  = "false"
    DIFY_INNER_API_URL             = "http://${local.api_name}:5001"
    DIFY_INNER_API_KEY             = local.plugin_inner_api_key
    PLUGIN_REMOTE_INSTALLING_HOST  = "0.0.0.0"
    PLUGIN_REMOTE_INSTALLING_PORT  = "5003"
    PLUGIN_WORKING_PATH            = "/app/storage/cwd"
    FORCE_VERIFYING_SIGNATURE      = "true"
    PYTHON_ENV_INIT_TIMEOUT        = "120"
    PLUGIN_MAX_EXECUTION_TIMEOUT   = "600"
    PLUGIN_STORAGE_TYPE            = "local"
    PLUGIN_STORAGE_LOCAL_ROOT      = "/app/storage"
    PLUGIN_INSTALLED_PATH          = "plugin"
    PLUGIN_PACKAGE_CACHE_PATH      = "plugin_packages"
    PLUGIN_MEDIA_CACHE_PATH        = "assets"
  })
  networks   = [module.dify_network.name]
  monitoring = local.monitoring
  depends_on = [module.postgres, module.redis]
}

# API service
module "api" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.api_name
  image          = local.api_image
  tag            = local.api_tag
  volumes        = local.app_storage_volumes
  env_vars = merge(local.shared_api_worker_env, {
    MODE = "api"
  })
  networks   = [module.dify_network.name, module.dify_ssrf_network.name]
  monitoring = local.monitoring
  depends_on = [module.postgres, module.redis, module.weaviate, module.sandbox, module.ssrf_proxy]
}

# Worker service (Celery)
module "worker" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.worker_name
  image          = local.api_image
  tag            = local.api_tag
  volumes        = local.app_storage_volumes
  env_vars = merge(local.shared_api_worker_env, {
    MODE = "worker"
  })
  networks   = [module.dify_network.name, module.dify_ssrf_network.name]
  monitoring = local.monitoring
  depends_on = [module.postgres, module.redis, module.weaviate, module.sandbox, module.ssrf_proxy]
}

# Worker beat service (Celery beat for scheduling)
module "worker_beat" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.worker_beat_name
  image          = local.api_image
  tag            = local.api_tag
  volumes        = local.app_storage_volumes
  env_vars = merge(local.shared_api_worker_env, {
    MODE = "beat"
  })
  networks   = [module.dify_network.name, module.dify_ssrf_network.name]
  monitoring = local.monitoring
  depends_on = [module.postgres, module.redis]
}

# Web frontend
module "web" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.web_name
  image          = local.web_image
  tag            = local.web_tag
  env_vars = {
    CONSOLE_API_URL               = local.public_base_url
    APP_API_URL                   = local.public_base_url
    FILES_URL                     = local.public_base_url
    NEXT_PUBLIC_DEPLOY_ENV         = "PRODUCTION"
    NEXT_PUBLIC_EDITION            = "SELF_HOSTED"
    NEXT_PUBLIC_COOKIE_DOMAIN      = ""
    NEXT_TELEMETRY_DISABLED        = "1"
    TEXT_GENERATION_TIMEOUT_MS     = "60000"
    MARKETPLACE_API_URL            = "https://marketplace.dify.ai"
    MARKETPLACE_URL                = "https://marketplace.dify.ai"
  }
  networks   = concat([module.dify_network.name], var.networks)
  monitoring = local.monitoring
  depends_on = [module.api]
}

# Nginx reverse proxy (internal, routes to API and Web)
resource "local_file" "nginx_conf" {
  filename = "${var.volume_path}/nginx/nginx.conf"
  content  = <<-EOT
    user nginx;
    worker_processes auto;
    error_log /var/log/nginx/error.log warn;
    pid /var/run/nginx.pid;

    events {
        worker_connections 1024;
    }

    http {
        include /etc/nginx/mime.types;
        default_type application/octet-stream;
        sendfile on;
        keepalive_timeout 65;
        client_max_body_size 100M;

        upstream api {
            server ${local.api_name}:5001;
        }

        upstream web {
            server ${local.web_name}:3000;
        }

        server {
            listen 80;
            server_name _;

            proxy_read_timeout 3600s;
            proxy_send_timeout 3600s;
            
            location /console/api {
                proxy_pass http://api;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "upgrade";
            }

            location /api {
                proxy_pass http://api;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "upgrade";
            }

            location /v1 {
                proxy_pass http://api;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "upgrade";
            }

            location /files {
                proxy_pass http://api;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
            }

            location /e/ {
                proxy_pass http://api;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
            }

            location / {
                proxy_pass http://web;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
            }
        }
    }
  EOT

  provisioner "local-exec" {
    command = "mkdir -p ${var.volume_path}/nginx"
  }
}

module "nginx" {
  source         = "../../10-services-generic/docker-service"
  container_name = "dify-nginx"
  image          = "nginx"
  tag            = "latest"
  volumes = [
    {
      host_path      = "${var.volume_path}/nginx/nginx.conf"
      container_path = "/etc/nginx/nginx.conf"
      read_only      = true
    }
  ]
  networks   = concat([module.dify_network.name], var.networks)
  monitoring = local.monitoring
  depends_on = [module.api, module.web, local_file.nginx_conf]
}

output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = "dify-nginx"
    primary_port = 80
    endpoint     = "http://dify-nginx:80"
    subdomains   = [var.subdomain]
    publish_via  = "tunnel"
  }
}

output "db_backup_config" {
  description = "Database backup configuration for Dify"
  value = {
    name         = "dify"
    type         = "postgres"
    host         = local.postgres_name
    port         = 5432
    database     = "dify"
    username     = "postgres"
    password_env = "DIFY_DB_PASSWORD"  # Env var name in Dify .env
    env_file     = local.env_file       # Path to Dify .env file
  }
}
