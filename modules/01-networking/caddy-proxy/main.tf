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
        // Pick the correct client IP placeholder depending on whether requests come via Cloudflare
        real_ip       = service.proxied ? "{http.request.header.CF-Connecting-IP}" : "{http.request.remote.host}"
        forwarded_for = service.proxied ? "{http.request.header.CF-Connecting-IP}" : "{http.request.remote.host}"
      }
    ]
  ])

  // Global options block for on-demand TLS (only when enabled)
  global_options = var.enable_ondemand_tls ? "{\n  email ${var.tls_email}\n  on_demand_tls {\n    ask ${var.ask_endpoint_url}\n  }\n}" : ""

  // Generate explicit site blocks from service_definitions
  explicit_sites = join("\n\n", [
    for site in local.caddy_site_configs : (
      site.has_custom_config
      ? "${site.site_address} {\n  tls ${var.tls_email}\n  ${site.custom_config}\n}"
      : "${site.site_address} {\n  tls ${var.tls_email}\n  reverse_proxy ${site.endpoint} {\n    header_up X-Real-IP ${site.real_ip}\n    header_up X-Forwarded-For ${site.forwarded_for}\n    header_up X-Forwarded-Proto {http.request.scheme}\n    header_up X-Forwarded-Host {http.request.host}\n${length(site.reverse_proxy_options) > 0 ? join("\n", [for key, value in site.reverse_proxy_options : "    ${key} ${value}"]) : ""}\n  }\n}"
    )
  ])

  // Catch-all block for on-demand TLS (routes to Dokploy Traefik)
  ondemand_catchall = var.enable_ondemand_tls ? "# Catch-all for on-demand TLS (Dokploy-managed domains)\n# Explicit site blocks above take precedence\nhttps:// {\n  tls {\n    on_demand\n  }\n  reverse_proxy ${var.dokploy_traefik_endpoint} {\n    header_up X-Real-IP {remote_host}\n    header_up X-Forwarded-For {remote_host}\n    header_up X-Forwarded-Proto {scheme}\n    header_up X-Forwarded-Host {host}\n  }\n}" : ""

  // Combine all parts into final Caddyfile
  caddyfile_content = join("\n\n", compact([
    local.global_options,
    local.explicit_sites,
    local.ondemand_catchall
  ]))
}

// Create Caddyfile in the volume path
resource "local_file" "caddyfile" {
  content  = local.caddyfile_content
  filename = "${var.volume_path}/caddy/Caddyfile"
}

// Create initial allowlist file for on-demand TLS ask endpoint
// This file is manually managed - domains are added one per line
resource "local_file" "allowlist" {
  content  = <<-EOT
    # Allowed domains for on-demand TLS certificate issuance
    # Add one domain per line (exact match only)
    # Lines starting with # are comments
    # 
    # Example:
    # myapp.example.com
    # admin.anotherdomain.org
  EOT
  filename = "${var.volume_path}/caddy/allowed-domains.txt"

  # Don't overwrite if file already exists with user content
  lifecycle {
    ignore_changes = [content]
  }
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

  networks   = var.networks

  depends_on = [
    local_file.caddyfile
  ]
}
