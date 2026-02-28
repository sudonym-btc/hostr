
output "project_id" {
  value = google_project.project.project_id
}

output "compose_vm_name" {
  value = google_compute_instance.compose_vm.name
}

output "compose_vm_zone" {
  value = google_compute_instance.compose_vm.zone
}

output "compose_runtime_secret_names" {
  value = [
    "ESCROW_PRIVATE_KEY",
    "BLOSSOM_DASHBOARD_PASSWORD",
  ]
}

# output "dns_zone_name" {
#   value = google_dns_managed_zone.main.name
# }

# output "static_ip" {
#   value = google_compute_address.static_ip.address
# }

# output "name_servers" {
#   value = google_dns_managed_zone.main.name_servers
# }

resource "local_file" "maps_api_key_file" {
  content  = google_apikeys_key.maps_api_key.key_string
  filename = "${path.module}/_local_outputs/${var.env}/maps_api_key.txt"
}
output "static_ip" {
  value = google_compute_address.static_ip.address
}
