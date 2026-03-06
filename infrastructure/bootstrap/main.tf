terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.21"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "google" {
  region = var.region
}

# ─── Projects ────────────────────────────────────────────────────────────────

resource "random_id" "production" {
  byte_length = 4
}

resource "random_id" "staging" {
  byte_length = 4
}

resource "google_project" "production" {
  name            = "${var.project_name}-production"
  project_id      = "${var.project_name}-production-${random_id.production.hex}"
  org_id          = var.org_id
  billing_account = var.billing_account
  deletion_policy = "DELETE"
}

resource "google_project" "staging" {
  name            = "${var.project_name}-staging"
  project_id      = "${var.project_name}-staging-${random_id.staging.hex}"
  org_id          = var.org_id
  billing_account = var.billing_account
  deletion_policy = "DELETE"
}

# ─── State bucket ────────────────────────────────────────────────────────────

resource "google_project_service" "storage" {
  project = google_project.production.project_id
  service = "storage.googleapis.com"
}

resource "google_storage_bucket" "terraform_state" {
  name                        = "${var.state_bucket_name}-${random_id.production.hex}"
  project                     = google_project.production.project_id
  location                    = var.state_bucket_location
  storage_class               = "STANDARD"
  force_destroy               = false
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 20
    }
    action {
      type = "Delete"
    }
  }

  depends_on = [google_project_service.storage]
}

# ─── DNS API ─────────────────────────────────────────────────────────────────

resource "google_project_service" "dns_production" {
  project = google_project.production.project_id
  service = "dns.googleapis.com"
}

resource "google_project_service" "dns_staging" {
  project = google_project.staging.project_id
  service = "dns.googleapis.com"
}

# ─── Cloud Resource Manager API ──────────────────────────────────────────────
# Required before Terraform (especially a CI service account) can manage
# google_project_service or google_project_iam_member resources.

resource "google_project_service" "crm_production" {
  project = google_project.production.project_id
  service = "cloudresourcemanager.googleapis.com"
}

resource "google_project_service" "crm_staging" {
  project = google_project.staging.project_id
  service = "cloudresourcemanager.googleapis.com"
}

# ─── Service Usage API ───────────────────────────────────────────────────────
# Must be enabled before Terraform (or a CI service account) can manage
# google_project_service resources on these projects.

resource "google_project_service" "serviceusage_production" {
  project = google_project.production.project_id
  service = "serviceusage.googleapis.com"
}

resource "google_project_service" "serviceusage_staging" {
  project = google_project.staging.project_id
  service = "serviceusage.googleapis.com"
}

# ─── Production zone (parent: hostr.network) ────────────────────────────────

resource "google_dns_managed_zone" "production" {
  name        = "main-zone"
  dns_name    = "${var.domain}."
  description = "Production zone for ${var.domain}"
  project     = google_project.production.project_id

  depends_on = [google_project_service.dns_production]
}

resource "google_dns_record_set" "mx" {
  name         = "${var.domain}."
  type         = "MX"
  ttl          = 300
  project      = google_project.production.project_id
  managed_zone = google_dns_managed_zone.production.name
  rrdatas      = var.mx_records
}

# ─── Staging zone (child: staging.hostr.network) ────────────────────────────

resource "google_dns_managed_zone" "staging" {
  name        = "main-zone"
  dns_name    = "staging.${var.domain}."
  description = "Staging zone for staging.${var.domain}"
  project     = google_project.staging.project_id

  depends_on = [google_project_service.dns_staging]
}

# ─── Delegation from production → staging ────────────────────────────────────

resource "google_dns_record_set" "staging_delegation" {
  name         = "staging.${var.domain}."
  type         = "NS"
  ttl          = 300
  project      = google_project.production.project_id
  managed_zone = google_dns_managed_zone.production.name
  rrdatas      = google_dns_managed_zone.staging.name_servers
}

# ─── IAM APIs ────────────────────────────────────────────────────────────────
# Required before Terraform can create service accounts or manage IAM.

resource "google_project_service" "iam_production" {
  project = google_project.production.project_id
  service = "iam.googleapis.com"
}

resource "google_project_service" "iam_staging" {
  project = google_project.staging.project_id
  service = "iam.googleapis.com"
}

resource "google_project_service" "iam_credentials_production" {
  project = google_project.production.project_id
  service = "iamcredentials.googleapis.com"
}

resource "google_project_service" "iam_credentials_staging" {
  project = google_project.staging.project_id
  service = "iamcredentials.googleapis.com"
}

# ─── CI Service Accounts ────────────────────────────────────────────────────
# Created here (rather than in the per-env main stack) so that the SA and its
# permissions exist BEFORE CI runs `terraform apply`.  This avoids a
# chicken-and-egg problem where the SA needs roles to refresh resources
# (e.g. google_apikeys_key requires serviceUsageConsumer) but would otherwise
# be granting itself those roles in the same apply.

resource "google_service_account" "ci_deploy_production" {
  project      = google_project.production.project_id
  account_id   = "ci-deploy"
  display_name = "CI Deploy (GitHub Actions)"

  depends_on = [google_project_service.iam_production]
}

resource "google_service_account" "ci_deploy_staging" {
  project      = google_project.staging.project_id
  account_id   = "ci-deploy"
  display_name = "CI Deploy (GitHub Actions)"

  depends_on = [google_project_service.iam_staging]
}

locals {
  ci_roles = [
    "roles/compute.admin",
    "roles/secretmanager.admin",
    "roles/iam.serviceAccountUser",
    "roles/storage.admin",
    "roles/dns.admin",
    "roles/resourcemanager.projectIamAdmin",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/serviceusage.serviceUsageConsumer",
  ]
}

resource "google_project_iam_member" "ci_deploy_production" {
  for_each = toset(local.ci_roles)

  project = google_project.production.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.ci_deploy_production.email}"
}

resource "google_project_iam_member" "ci_deploy_staging" {
  for_each = toset(local.ci_roles)

  project = google_project.staging.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.ci_deploy_staging.email}"
}

# The TF state bucket lives in the production project. Both envs need access.
resource "google_storage_bucket_iam_member" "ci_deploy_state_production" {
  bucket = google_storage_bucket.terraform_state.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.ci_deploy_production.email}"
}

resource "google_storage_bucket_iam_member" "ci_deploy_state_staging" {
  bucket = google_storage_bucket.terraform_state.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.ci_deploy_staging.email}"
}
