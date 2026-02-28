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
