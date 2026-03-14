terraform {
  required_version = ">= 1.5.0"

  backend "gcs" {}

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.21"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 7.21"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

locals {
  project_base_name = "${var.project_name}-${var.env}"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project               = var.project_id
  region                = var.region
  billing_project       = var.project_id
  user_project_override = true
}

# ─── IAM ─────────────────────────────────────────────────────────────────────

resource "google_project_iam_member" "service_usage_admin" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageAdmin"
  member  = "user:admin@hostr.network"
}

resource "google_project_iam_member" "logging_admin" {
  project = var.project_id
  role    = "roles/logging.admin"
  member  = "user:admin@hostr.network"
}

resource "google_project_iam_member" "quota_administrator" {
  project = var.project_id
  role    = "roles/servicemanagement.quotaAdmin"
  member  = "user:admin@hostr.network"
}

# ─── APIs ────────────────────────────────────────────────────────────────────

resource "google_project_service" "logging" {
  project = var.project_id
  service = "logging.googleapis.com"

  depends_on = [
    google_project_iam_member.service_usage_admin,
    google_project_iam_member.quota_administrator,
  ]
}

# ─── Maps ────────────────────────────────────────────────────────────────────

resource "google_project_service" "api_keys" {
  project = var.project_id
  service = "apikeys.googleapis.com"

  depends_on = [
    google_project_iam_member.service_usage_admin,
    google_project_iam_member.quota_administrator,
  ]
}

resource "google_project_service" "maps" {
  project = var.project_id
  service = "geocoding-backend.googleapis.com"

  depends_on = [
    google_project_iam_member.service_usage_admin,
    google_project_iam_member.quota_administrator,
  ]
}

resource "google_project_service" "maps_places" {
  project = var.project_id
  service = "places.googleapis.com"

  depends_on = [
    google_project_iam_member.service_usage_admin,
    google_project_iam_member.quota_administrator,
  ]
}

resource "google_project_service" "maps_javascript" {
  project = var.project_id
  service = "maps-backend.googleapis.com"

  depends_on = [
    google_project_iam_member.service_usage_admin,
    google_project_iam_member.quota_administrator,
  ]
}

resource "google_apikeys_key" "maps_api_key" {
  provider = google-beta
  project  = var.project_id

  display_name = "Maps API Key"
  name         = "maps-api-key-${var.env}"

  restrictions {
    api_targets {
      service = "geocoding-backend.googleapis.com"
    }
    api_targets {
      service = "places.googleapis.com"
    }
    api_targets {
      service = "maps-backend.googleapis.com"
    }
  }

  depends_on = [
    google_project_service.maps,
    google_project_service.maps_places,
    google_project_service.maps_javascript,
    google_project_service.api_keys,
  ]
}

resource "google_project_service" "maps_ios" {
  project = var.project_id
  service = "maps-ios-backend.googleapis.com"
}

resource "google_apikeys_key" "maps_ios_key" {
  project  = var.project_id
  provider = google-beta

  display_name = "Maps API Key"
  name         = "maps-api-ios-key-${var.env}"

  restrictions {
    api_targets {
      service = "geocoding-backend.googleapis.com"
    }
    api_targets {
      service = "places.googleapis.com"
    }
    api_targets {
      service = "maps-ios-backend.googleapis.com"
    }
    api_targets {
      service = "maps-android-backend.googleapis.com"
    }
    api_targets {
      service = "maps-backend.googleapis.com"
    }
  }

  depends_on = [
    google_project_service.maps,
    google_project_service.maps_places,
    google_project_service.maps_javascript,
    google_project_service.api_keys,
    google_project_service.maps_ios,
  ]
}

resource "local_file" "maps_api_key_file" {
  content  = google_apikeys_key.maps_api_key.key_string
  filename = "${path.module}/_local_outputs/${var.env}/maps_api_key.txt"
}
