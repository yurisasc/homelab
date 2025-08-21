variable "volume_path" {
  description = "Base directory for Sabnzbd config"
  type        = string
}
variable "downloads_path" {
  description = "Directory for downloads mounted at /downloads"
  type        = string
}
variable "networks" {
  description = "List of networks to attach"
  type        = list(string)
  default     = []
}

locals {
  container_name = "sabnzbd"
  image          = "lscr.io/linuxserver/sabnzbd"
  tag            = "latest"
  monitoring     = true
  internal_port  = 8080

  env_vars = {
    # Add typical env like PUID/PGID/TZ if desired via the generic module interface
  }

  volumes = [
    {
      host_path      = var.volume_path,
      container_path = "/config",
      read_only      = false
    },
    {
      host_path      = var.downloads_path,
      container_path = "/data/usenet/downloads",
      read_only      = false
    }
  ]

  healthcheck = {
    test     = ["CMD", "curl", "--fail", "http://127.0.0.1:8080"]
    interval = "60s"
    timeout  = "5s"
    retries  = 10
  }
}

module "sabnzbd" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.container_name
  image          = local.image
  tag            = local.tag
  env_vars       = local.env_vars
  volumes        = local.volumes
  networks       = var.networks
  monitoring     = local.monitoring
  healthcheck    = local.healthcheck
}

output "service_definition" {
  description = "Service definition for Sabnzbd (not published)"
  value = {
    name         = local.container_name
    primary_port = local.internal_port
    endpoint     = "http://${local.container_name}:${local.internal_port}"
    subdomains   = ["sabnzbd"]
    publish_via  = "tunnel"
    proxied      = true
  }
}
