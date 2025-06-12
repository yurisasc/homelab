output "dns_records" {
  description = "Map of DNS records created"
  value       = cloudflare_record.service
}

output "record_hostnames" {
  description = "List of hostnames for which DNS records were created"
  value       = keys(local.all_records)
}
