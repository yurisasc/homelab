// Cloudflare Tunnel module
// This module creates a Cloudflare tunnel and deploys a cloudflared container

terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.1"
    }
  }
}

// Generate a random secret for the tunnel if none provided
resource "random_id" "tunnel_secret" {
  count       = var.tunnel_secret == "" ? 1 : 0
  byte_length = 35
}

// Create the Cloudflare Tunnel
resource "cloudflare_zero_trust_tunnel_cloudflared" "this" {
  account_id = var.cloudflare_account_id
  name       = var.tunnel_name
  secret     = var.tunnel_secret != "" ? var.tunnel_secret : random_id.tunnel_secret[0].b64_std
}

locals {  
  all_ingress_rules = [for rule in var.ingress_rules : rule if rule != null]
}

// Configure tunnel routing
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "this" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.this.id
  
  config {
    // Add all service ingress rules
    dynamic "ingress_rule" {
      for_each = local.all_ingress_rules
      content {
        hostname = ingress_rule.value.hostname
        service  = ingress_rule.value.service
      }
    }
    
    // Default catch-all rule (required)
    ingress_rule {
      service = "http_status:404"
    }
  }
}

// Create DNS record for each service
resource "cloudflare_record" "service" {
  for_each = { for rule in var.ingress_rules : rule.hostname => rule }
  
  zone_id = var.cloudflare_zone_id
  name    = split(".", each.value.hostname)[0] // Extract subdomain
  content = "${cloudflare_zero_trust_tunnel_cloudflared.this.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

// Set up the Docker container
locals {
  container_name = var.container_name != "" ? var.container_name : "cloudflared-${var.tunnel_name}"
  image_tag      = var.image_tag != "" ? var.image_tag : "latest"
}

module "cloudflared" {
  source = "../../10-services-generic/docker-service"

  container_name = var.container_name
  image          = "cloudflare/cloudflared"
  tag            = local.image_tag
  
  // Environment variables with tunnel token
  env_vars      = {
    TUNNEL_TOKEN = cloudflare_zero_trust_tunnel_cloudflared.this.tunnel_token
  }
  
  // Command to run tunnel
  command       = ["tunnel", "--no-autoupdate", "run"]
  
  // Restart policy
  restart_policy = "unless-stopped"
  
  // Enable monitoring for the container via Watchtower if specified
  monitoring    = var.monitoring

  networks      = var.networks
}
