terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}

locals {
  container_name = var.container_name != "" ? var.container_name : "caddy-proxy"
  image_tag      = var.image_tag != "" ? var.image_tag : "latest"

  // Filter services to only include those that should be published via reverse proxy
  proxy_services = [
    for service in var.service_definitions :
    service if length(service.subdomains) > 0 && (service.publish_via == "reverse_proxy" || service.publish_via == "both")
  ]

  // Transform service definitions into Caddyfile blocks
  caddy_site_configs = flatten([
    for service in local.proxy_services :
    [
      for subdomain in service.subdomains : {
        site_address          = "${subdomain}.${var.domain}"
        endpoint              = service.endpoint
        service_name          = service.name
        tls_email             = var.tls_email
        has_custom_config     = service.caddy_config != ""
        custom_config         = service.caddy_config
        reverse_proxy_options = service.caddy_options
        proxied               = service.proxied
      }
    ]
  ])

  // Generate the main Caddyfile content
  caddyfile_content = join("\n\n", [
    for site in local.caddy_site_configs :
    site.has_custom_config ?
    // Use the custom Caddy config if provided
    <<-EOT
    ${site.site_address} {
      tls ${var.tls_email}
      ${site.custom_config}
    }
    EOT
    :
    // Otherwise use the standard reverse proxy config with options
    <<-EOT
    ${site.site_address} {
      tls ${var.tls_email}
      reverse_proxy ${site.endpoint} {
        ${join("\n        ", [
    for key, value in site.reverse_proxy_options :
    "${key} ${value}"
])}
      }
    }
    EOT
])
}

resource "docker_volume" "caddy_config" {
  name = "${local.container_name}_config"
}

// Create Caddyfile in the volume path
resource "local_file" "caddyfile" {
  content  = local.caddyfile_content
  filename = "${var.volume_path}/caddy/Caddyfile"
}

module "dns_records" {
  count   = var.cloudflare_zone_id != "" ? 1 : 0
  source  = "../../10-services-generic/cloudflare-dns"
  zone_id = var.cloudflare_zone_id
  dns_records = {
    for site in local.caddy_site_configs : site.site_address => {
      name    = site.site_address
      value   = var.external_ip
      type    = "A"
      proxied = site.proxied
      ttl     = 1
    }
  }
}

module "caddy" {
  source = "../../10-services-generic/docker-service"

  container_name = local.container_name
  image          = "caddy"
  tag            = local.image_tag

  volumes = [
    {
      host_path      = "${var.volume_path}/caddy/data"
      container_path = "/data"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/caddy/config"
      container_path = "/config"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/caddy/Caddyfile"
      container_path = "/etc/caddy/Caddyfile"
      read_only      = true
    }
  ]

  ports = [
    {
      external = "80"
      internal = "80"
      protocol = "tcp"
    },
    {
      external = "443"
      internal = "443"
      protocol = "tcp"
    }
  ]

  monitoring = var.monitoring
  networks   = var.networks
}
