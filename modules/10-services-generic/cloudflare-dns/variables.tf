variable "zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
}

variable "dns_records" {
  description = "Map of DNS records to create"
  type = map(object({
    name    = string
    value   = string
    type    = string
    proxied = bool
    ttl     = number
  }))
  default = {}
}

variable "hostnames" {
  description = "List of hostnames to create DNS records for"
  type        = list(string)
  default     = []
}

variable "target_content" {
  description = "Target content/value for the DNS records when using hostnames list"
  type        = string
  default     = ""
}

variable "record_type" {
  description = "Record type for the DNS records when using hostnames list"
  type        = string
  default     = "CNAME"
}

variable "proxied" {
  description = "Whether the records should be proxied through Cloudflare"
  type        = bool
  default     = true
}

variable "ttl" {
  description = "TTL for the records (only used when proxied=false)"
  type        = number
  default     = 1 # Auto
}
