terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

variable "volume_path" {
  description = "Base directory for volumes"
  type        = string
}

variable "networks" {
  description = "Networks to attach containers to"
  type        = list(string)
  default     = []
}

variable "backup_networks" {
  description = "List of networks for backup access to database"
  type        = list(string)
  default     = []
}

variable "image_tag" {
  description = "The tag of the Dokploy Docker image to use"
  type        = string
  default     = "latest"
}

variable "traefik_tag" {
  description = "The tag of the Traefik Docker image to use"
  type        = string
  default     = "v3.6.1"
}


locals {
  # Read secrets from local .env file (same pattern as arr module)
  env_file = "${path.module}/.env"

  # Container names
  dokploy_name         = "dokploy"
  postgres_name        = "dokploy-postgres"
  redis_name           = "dokploy-redis"
  traefik_name         = "dokploy-traefik"
  dokploy_network_name = "dokploy-network"

  # Secrets from .env file
  postgres_password = provider::dotenv::get_by_key("DOKPLOY_POSTGRES_PASSWORD", local.env_file)
  advertise_addr    = provider::dotenv::get_by_key("DOKPLOY_ADVERTISE_ADDR", local.env_file)

  # Ports
  dokploy_port  = 3000
  postgres_port = 5432
  redis_port    = 6379
  traefik_http  = 80
  traefik_https = 443

  # Images
  postgres_image = "postgres"
  postgres_tag   = "16"
  redis_image    = "redis"
  redis_tag      = "7"
  dokploy_image  = "dokploy/dokploy"
  traefik_image  = "traefik"

  monitoring = true
}

# Create dedicated dokploy-network for internal communication
resource "docker_network" "dokploy_network" {
  name       = local.dokploy_network_name
  driver     = "overlay"
  attachable = true
}

# PostgreSQL container
module "dokploy_postgres" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.postgres_name
  image          = local.postgres_image
  tag            = local.postgres_tag

  env_vars = {
    POSTGRES_USER     = "dokploy"
    POSTGRES_DB       = "dokploy"
    POSTGRES_PASSWORD = local.postgres_password
  }

  volumes = [
    {
      host_path      = "${var.volume_path}/postgres"
      container_path = "/var/lib/postgresql/data"
      read_only      = false
    }
  ]

  networks   = concat([docker_network.dokploy_network.name], var.backup_networks)
  monitoring = local.monitoring
}

# Redis container
module "dokploy_redis" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.redis_name
  image          = local.redis_image
  tag            = local.redis_tag

  volumes = [
    {
      host_path      = "${var.volume_path}/redis"
      container_path = "/data"
      read_only      = false
    }
  ]

  networks   = concat([docker_network.dokploy_network.name], var.networks)
  monitoring = local.monitoring
}

# Dokploy app container
module "dokploy_app" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.dokploy_name
  image          = local.dokploy_image
  tag            = var.image_tag

  env_vars = {
    # ADVERTISE_ADDR is the private IP - we use container name for internal networking
    ADVERTISE_ADDR = local.advertise_addr
    # Database connection using internal dokploy-network
    DATABASE_URL = "postgresql://dokploy:${local.postgres_password}@${local.postgres_name}:${local.postgres_port}/dokploy"
    REDIS_URL    = "redis://${local.redis_name}:${local.redis_port}"
  }

  volumes = [
    {
      host_path      = "/var/run/docker.sock"
      container_path = "/var/run/docker.sock"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/config"
      container_path = "/etc/dokploy"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/docker-config"
      container_path = "/root/.docker"
      read_only      = false
    }
  ]

  # No host port - accessed via Caddy reverse proxy
  networks   = concat([docker_network.dokploy_network.name], var.networks)
  monitoring = local.monitoring

  depends_on = [
    module.dokploy_postgres,
    module.dokploy_redis
  ]
}

# Traefik container - NO HOST PORTS
# Caddy will proxy to this container internally
module "dokploy_traefik" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.traefik_name
  image          = local.traefik_image
  tag            = var.traefik_tag

  volumes = [
    {
      host_path      = "${var.volume_path}/config/traefik/traefik.yml"
      container_path = "/etc/traefik/traefik.yml"
      read_only      = true
    },
    {
      host_path      = "${var.volume_path}/config/traefik/dynamic"
      container_path = "/etc/dokploy/traefik/dynamic"
      read_only      = false
    },
    {
      host_path      = "/var/run/docker.sock"
      container_path = "/var/run/docker.sock"
      read_only      = true
    }
  ]

  # NO ports - internal access only (Option 2: Traefik listens on 80/443 internally)
  # Caddy proxies to http://dokploy-traefik:80 for on-demand TLS domains
  networks   = concat([docker_network.dokploy_network.name], var.networks)
  monitoring = local.monitoring

  depends_on = [
    module.dokploy_app
  ]
}

# Create initial Traefik config directory and base config file
resource "local_file" "traefik_config" {
  filename = "${var.volume_path}/config/traefik/traefik.yml"
  content  = <<-EOT
    # Traefik configuration for Dokploy (managed by Terraform)
    # Internal-only: no host port publishing, accessed via Caddy
    api:
      dashboard: false
      insecure: false

    entryPoints:
      web:
        address: ":80"
      websecure:
        address: ":443"

    providers:
      file:
        directory: /etc/dokploy/traefik/dynamic
        watch: true
      swarm:
        endpoint: "unix:///var/run/docker.sock"
        exposedByDefault: false
        network: ${local.dokploy_network_name}

    log:
      level: INFO
  EOT
}

# Ensure dynamic config directory exists
resource "local_file" "traefik_dynamic_placeholder" {
  filename = "${var.volume_path}/config/traefik/dynamic/.gitkeep"
  content  = "# Placeholder for Dokploy dynamic Traefik configs\n"
}

output "service_definition" {
  description = "Service definition for Dokploy UI (reverse proxy)"
  value = {
    name         = local.dokploy_name
    primary_port = local.dokploy_port
    endpoint     = "http://${local.dokploy_name}:${local.dokploy_port}"
    subdomains   = ["deploy"]
    publish_via  = "tunnel"
    proxied      = true
  }
}

output "traefik_endpoint" {
  description = "Internal Traefik endpoint for on-demand TLS routing (no host ports)"
  value       = "http://${local.traefik_name}:${local.traefik_http}"
}

output "dokploy_network_name" {
  description = "Name of the Dokploy internal network"
  value       = docker_network.dokploy_network.name
}

output "db_backup_config" {
  description = "Database backup configuration for Dokploy"
  value = {
    name         = "dokploy"
    type         = "postgres"
    host         = local.postgres_name
    port         = local.postgres_port
    database     = "dokploy"
    username     = "dokploy"
    password_env = "DOKPLOY_POSTGRES_PASSWORD"  # Env var name in Dokploy .env
    env_file     = local.env_file                 # Path to Dokploy .env file
  }
}
