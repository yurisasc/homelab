terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}

locals {
  hostname_records = length(var.hostnames) > 0 ? {
    for hostname in var.hostnames :
    hostname => {
      name    = split(".", hostname)[0] // Extract subdomain
      value   = var.target_content
      type    = var.record_type
      proxied = var.proxied
      ttl     = var.ttl
    }
  } : {}

  all_records = merge(local.hostname_records, var.dns_records)
}

resource "cloudflare_record" "service" {
  for_each = local.all_records

  zone_id = var.zone_id
  name    = each.value.name
  content = each.value.value
  type    = each.value.type
  proxied = each.value.proxied
  ttl     = each.value.ttl
}
