resource "random_id" "project_id" {
  byte_length = 4 # Generates a random string with 8 characters (4 bytes * 2 hex digits per byte)
}

provider "google" {
  project = "${var.project_name}-${var.env}-${random_id.project_id.hex}"
  region  = var.region
}

provider "google-beta" {
  project               = "${var.project_name}-${var.env}-${random_id.project_id.hex}"
  region                = var.region
  billing_project       = "${var.project_name}-${var.env}-${random_id.project_id.hex}"
  user_project_override = true
}

resource "google_project" "project" {
  name            = "${var.project_name}-${var.env}"
  project_id      = "${var.project_name}-${var.env}-${random_id.project_id.hex}"
  org_id          = var.org_id
  billing_account = var.billing_account
}

resource "google_project_iam_member" "service_usage_admin" {
  project = google_project.project.project_id
  role    = "roles/serviceusage.serviceUsageAdmin"
  member  = "user:admin@hostr.network"
}
resource "google_project_iam_member" "logging_admin" {
  project = google_project.project.project_id
  role    = "roles/logging.admin"
  member  = "user:admin@hostr.network"
}

resource "google_project_iam_member" "quota_administrator" {
  project = google_project.project.project_id
  role    = "roles/servicemanagement.quotaAdmin"
  member  = "user:admin@hostr.network"
}

resource "google_project_service" "api_keys" {
  project = google_project.project.project_id
  service = "apikeys.googleapis.com"

  depends_on = [
    google_project_iam_member.service_usage_admin,
    google_project_iam_member.quota_administrator
  ]
}

resource "google_project_service" "logging" {
  project = google_project.project.project_id
  service = "logging.googleapis.com"

  depends_on = [
    google_project_iam_member.service_usage_admin,
    google_project_iam_member.quota_administrator
  ]
}
resource "google_project_service" "maps" {
  project = google_project.project.project_id
  service = "geocoding-backend.googleapis.com"

  depends_on = [
    google_project_iam_member.service_usage_admin,
    google_project_iam_member.quota_administrator
  ]
}

resource "google_project_service" "maps_places" {
  project = google_project.project.project_id
  service = "places.googleapis.com"

  depends_on = [
    google_project_iam_member.service_usage_admin,
    google_project_iam_member.quota_administrator
  ]
}

resource "google_apikeys_key" "maps_api_key" {
  provider = google-beta
  project  = google_project.project.project_id

  display_name = "Maps API Key"
  name         = "maps-api-key"

  restrictions {
    api_targets {
      service = "geocoding-backend.googleapis.com"
    }
    api_targets {
      service = "places.googleapis.com"
    }
  }

  depends_on = [
    google_project_service.maps,
    google_project_service.api_keys
  ]
}

# Maps iOS API
resource "google_project_service" "maps_ios" {
  project = google_project.project.project_id
  service = "maps-ios-backend.googleapis.com"
}

resource "google_apikeys_key" "maps_ios_key" {
  project  = google_project.project.project_id
  provider = google-beta

  display_name = "Maps API Key"
  name         = "maps-api-ios-key"

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

    // just added might be incorrect
    api_targets {
      service = "maps-backend.googleapis.com"
    }
  }

  depends_on = [
    google_project_service.maps,
    google_project_service.api_keys
  ]
}

# @todo Maps JavaScript API

resource "google_project_iam_member" "maps_ios_key" {
  project = google_project.project.project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "serviceAccount:${google_apikeys_key.maps_ios_key.name}@${google_project.project.project_id}.iam.gserviceaccount.com"
}

# Maps Android API
# resource "google_project_service" "maps_android" {
#   project = google_project.project.project_id
#   service = "maps-android-backend.googleapis.com"
# }

# resource "google_api_key" "maps_android_key" {
#   project = google_project.project.project_id
# }

# resource "google_project_iam_member" "maps_android_key" {
#   project = google_project.project.project_id
#   role    = "roles/serviceusage.serviceUsageConsumer"
#   member  = "serviceAccount:${google_api_key.maps_android_key.name}@${google_project.project.project_id}.iam.gserviceaccount.com"
# }
