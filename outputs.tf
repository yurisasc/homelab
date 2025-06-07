output "services" {
  description = "Service definitions for all services"
  value = [
    for service in module.services.service_definitions : {
      name     = service.name
      endpoint = contains(keys(service), "hostnames") ? "${service.hostnames[0]}.${module.cloudflare_globals.domain}" : service.endpoint
    }
  ]
}
