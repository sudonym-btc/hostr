output "production_project_id" {
  value = google_project.production.project_id
}

output "staging_project_id" {
  value = google_project.staging.project_id
}

output "state_bucket_name" {
  value = google_storage_bucket.terraform_state.name
}

output "production_zone_name" {
  value = google_dns_managed_zone.production.name
}

output "production_name_servers" {
  description = "Set these at your domain registrar."
  value       = google_dns_managed_zone.production.name_servers
}

output "staging_zone_name" {
  value = google_dns_managed_zone.staging.name
}

output "staging_name_servers" {
  value = google_dns_managed_zone.staging.name_servers
}

# ── CI ────────────────────────────────────────────────────────────────────────

output "ci_service_account_email_production" {
  value = google_service_account.ci_deploy_production.email
}

output "ci_service_account_email_staging" {
  value = google_service_account.ci_deploy_staging.email
}
