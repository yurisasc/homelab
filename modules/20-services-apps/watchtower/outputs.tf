output "container_name" {
  description = "Name of the created Watchtower container"
  value       = module.watchtower.container_name
}

output "container_id" {
  description = "ID of the created Watchtower container"
  value       = module.watchtower.container_id
}

output "image_id" {
  description = "ID of the Watchtower image used"
  value       = module.watchtower.image_id
}
