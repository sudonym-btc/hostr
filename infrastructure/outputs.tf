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
  value = local.compose_runtime_secret_names
}

output "rif_relay_admin_secret_name" {
  value = local.rif_relay_admin_secret_name
}

output "static_ip" {
  value = google_compute_address.static_ip.address
}

# ── CI / Workload Identity Federation ─────────────────────────────────────────

output "ci_workload_identity_provider" {
  description = "Full resource name for the GitHub OIDC provider. Set as GCP_WORKLOAD_IDENTITY_PROVIDER in GitHub environment variables."
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "ci_service_account_email" {
  description = "CI service account email. Set as GCP_SERVICE_ACCOUNT_EMAIL in GitHub environment variables."
  value       = data.google_service_account.ci_deploy.email
}

# ── Artifact Registry ─────────────────────────────────────────────────────────

output "docker_registry" {
  description = "Artifact Registry Docker base URL. Set as DOCKER_REGISTRY in GitHub environment variables."
  value       = "${google_artifact_registry_repository.docker.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker.repository_id}"
}
