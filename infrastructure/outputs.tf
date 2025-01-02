
output "project_id" {
  value = google_project.project.project_id
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
output "loadbalancer_ip" {
  value = kubernetes_service_v1.relay.status.0.load_balancer.0.ingress.0.ip
}