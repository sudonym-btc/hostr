# ─── Artifact Registry (Docker images built in CI) ───────────────────────────

resource "google_project_service" "artifact_registry" {
  project = var.project_id
  service = "artifactregistry.googleapis.com"

  depends_on = [
    google_project_iam_member.service_usage_admin,
    google_project_iam_member.quota_administrator,
  ]
}

resource "google_artifact_registry_repository" "docker" {
  project       = var.project_id
  location      = var.region
  repository_id = "hostr"
  description   = "Docker images for hostr compose services"
  format        = "DOCKER"

  cleanup_policy_dry_run = false

  # Keep the 10 most recent tagged versions per image; delete untagged after 7 days.
  cleanup_policies {
    id     = "keep-recent"
    action = "KEEP"
    most_recent_versions {
      keep_count = 10
    }
  }

  cleanup_policies {
    id     = "gc-untagged"
    action = "DELETE"
    condition {
      tag_state  = "UNTAGGED"
      older_than = "604800s" # 7 days
    }
  }

  depends_on = [google_project_service.artifact_registry]
}

# ── IAM: CI service account can push images ──────────────────────────────────
resource "google_artifact_registry_repository_iam_member" "ci_push" {
  project    = var.project_id
  location   = google_artifact_registry_repository.docker.location
  repository = google_artifact_registry_repository.docker.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${data.google_service_account.ci_deploy.email}"
}

# ── IAM: Compose VM service account can pull images ──────────────────────────
resource "google_artifact_registry_repository_iam_member" "vm_pull" {
  project    = var.project_id
  location   = google_artifact_registry_repository.docker.location
  repository = google_artifact_registry_repository.docker.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.compose_vm.email}"
}
