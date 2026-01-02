terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

variable "image_tag" {
  description = "Tag of the Crawl4AI image to use"
  type        = string
  default     = "latest"
}

variable "volume_path" {
  description = "Host path for Crawl4AI data volumes"
  type        = string
}

variable "networks" {
  description = "List of networks to which the container should be attached"
  type        = list(string)
  default     = []
}

locals {
  container_name = "crawl4ai"
  image          = "unclecode/crawl4ai"
  image_tag      = var.image_tag
  service_port   = provider::dotenv::get_by_key("PORT", local.env_file)
  env_file       = "${path.module}/.env"

  # Define volumes
  default_volumes = [
    {
      container_path = "/dev/shm"
      host_path      = "/dev/shm"
      read_only      = false
    },
    {
      container_path = "/app/config.yml"
      host_path      = "${var.volume_path}/config.yml"
      read_only      = false
    }
  ]

  # Define ports
  ports = [
    {
      internal = local.service_port
      external = local.service_port
      protocol = "tcp"
    }
  ]

  # Environment variables
  env_vars = {
    OPENAI_API_KEY    = provider::dotenv::get_by_key("OPENAI_API_KEY", local.env_file)
    DEEPSEEK_API_KEY  = provider::dotenv::get_by_key("DEEPSEEK_API_KEY", local.env_file)
    ANTHROPIC_API_KEY = provider::dotenv::get_by_key("ANTHROPIC_API_KEY", local.env_file)
    GROQ_API_KEY      = provider::dotenv::get_by_key("GROQ_API_KEY", local.env_file)
    TOGETHER_API_KEY  = provider::dotenv::get_by_key("TOGETHER_API_KEY", local.env_file)
    MISTRAL_API_KEY   = provider::dotenv::get_by_key("MISTRAL_API_KEY", local.env_file)
    GEMINI_API_TOKEN  = provider::dotenv::get_by_key("GEMINI_API_TOKEN", local.env_file)
  }

  # Healthcheck configuration
  healthcheck = {
    test         = ["CMD", "curl", "-f", "http://localhost:${local.service_port}/health"]
    interval     = "30s"
    timeout      = "10s"
    retries      = 3
    start_period = "40s"
  }
}

module "crawl4ai" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.container_name
  image          = local.image
  tag            = local.image_tag
  volumes        = local.default_volumes
  ports          = local.ports
  env_vars       = local.env_vars
  networks       = var.networks
  healthcheck    = local.healthcheck
  user           = "appuser"
}

output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = local.service_port
    endpoint     = "http://${local.container_name}:${local.service_port}"
  }
}
