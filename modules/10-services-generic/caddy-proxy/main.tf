terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

# Generate Caddyfile content
locals {
  # Generate the Caddyfile header
  caddyfile_header = "# Global options\n{\n  admin :2019\n}\n\n"
  
  # Generate site configurations - using separate HTTP and HTTPS blocks but with different hostnames
  site_blocks = flatten([
    for site in var.sites : [
      # HTTPS configuration
      "# Site configuration for ${site.domain} (HTTPS)",
      "${site.domain}:${var.https_port} {",
      "  # TLS configuration",
      "  tls internal",
      "",
      "  # Route configurations",
      join("\n\n  ", [
        for route in site.routes : <<-ROUTE
        # Route: ${route.path}
        handle ${route.path} {
          reverse_proxy ${route.target_host}:${route.target_port} {
            ${route.websocket ? "# WebSocket protocol handling\n      header_up Connection \"Upgrade\"\n      header_up Upgrade \"websocket\"" : ""}
          }
        }
        ROUTE
      ]),
      "}",
      "",
      # HTTP configuration with redirect to HTTPS
      "# HTTP redirect for ${site.domain}",
      ":${var.http_port} {",
      "  redir https://${site.domain}:${var.https_port}{uri} permanent",
      "}"
    ]
  ])
  
  # Combine everything into the final Caddyfile
  caddyfile_content = "${local.caddyfile_header}${join("\n\n", local.site_blocks)}"
  
  # Define volumes for Caddy
  volumes = [
    {
      host_path      = "${var.volume_path}/Caddyfile"
      container_path = "/etc/caddy/Caddyfile"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/data"
      container_path = "/data"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/config"
      container_path = "/config"
      read_only      = false
    }
  ]
  
  # Create data directories if they don't exist
  data_directories = [
    var.volume_path,
    "${var.volume_path}/data",
    "${var.volume_path}/config"
  ]
  
  # Environment variables - convert to the format docker_container resource expects
  env_vars = var.networks != [] ? ["CADDY_INGRESS_NETWORKS=${join(",", var.networks)}"] : []
  
  # Health check
  healthcheck = {
    test     = ["CMD", "wget", "--spider", "--quiet", "http://localhost:80/healthz"]
    interval = "30s"
    timeout  = "3s"
    retries  = 3
  }
}

# Create data directories
resource "null_resource" "create_directories" {
  count = length(local.data_directories)
  
  provisioner "local-exec" {
    command = "mkdir -p ${local.data_directories[count.index]}"
  }
}

# Create Caddyfile
resource "local_file" "caddyfile" {
  content  = local.caddyfile_content
  filename = "${var.volume_path}/Caddyfile"
  depends_on = [null_resource.create_directories]
}

# Pull the image
resource "docker_image" "caddy" {
  name = "${var.image}:${var.tag}"
}

# Create the container
resource "docker_container" "caddy" {
  name  = var.container_name
  image = docker_image.caddy.image_id
  
  restart = "unless-stopped"
  
  # Map ports similar to Nginx Proxy Manager
  ports {
    internal = 80
    external = var.http_port
    protocol = "tcp"
  }
  
  ports {
    internal = 443
    external = var.https_port
    protocol = "tcp"
  }
  
  # Admin interface port
  ports {
    internal = 2019  # Caddy admin API port
    external = var.admin_port
    protocol = "tcp"
  }
  
  # Set up volumes
  dynamic "volumes" {
    for_each = local.volumes
    content {
      host_path      = volumes.value.host_path
      container_path = volumes.value.container_path
      read_only      = volumes.value.read_only
    }
  }
  
  # Set environment variables as a list of strings in KEY=VALUE format
  env = local.env_vars
  
  # Set networks
  dynamic "networks_advanced" {
    for_each = var.networks
    content {
      name = networks_advanced.value
    }
  }
  
  # Set health check
  healthcheck {
    test     = local.healthcheck.test
    interval = local.healthcheck.interval
    timeout  = local.healthcheck.timeout
    retries  = local.healthcheck.retries
  }
  
  # Add watchtower label if monitoring is enabled
  labels {
    label = "com.centurylinklabs.watchtower.enable"
    value = var.monitoring ? "true" : "false"
  }
  
  # Make sure Caddyfile is created before starting container
  depends_on = [local_file.caddyfile]
}
