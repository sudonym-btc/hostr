output "project_id" {
  value = var.project_id
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

output "static_ip" {
  value = google_compute_address.static_ip.address
}
