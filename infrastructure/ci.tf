# ─── Workload Identity Federation (GitHub Actions → GCP) ─────────────────────
#
# Allows the GitHub Actions workflow to authenticate to GCP without a
# long-lived service account key.  Each workflow run receives a short-lived
# OIDC token from GitHub that GCP exchanges for temporary SA credentials.
#
# After `terraform apply`, copy the outputs into GitHub **environment**
# variables (Settings → Environments → staging / production):
#
#   GCP_WORKLOAD_IDENTITY_PROVIDER = <ci_workload_identity_provider output>
#   GCP_SERVICE_ACCOUNT_EMAIL      = <ci_service_account_email output>

# ── APIs ──────────────────────────────────────────────────────────────────────

resource "google_project_service" "iam_credentials" {
  project = var.project_id
  service = "iamcredentials.googleapis.com"
}

resource "google_project_service" "iam" {
  project = var.project_id
  service = "iam.googleapis.com"
}

# ── Workload Identity Pool ────────────────────────────────────────────────────

resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = "github-actions"
  display_name              = "GitHub Actions"
  description               = "OIDC pool for GitHub Actions CI/CD"

  depends_on = [google_project_service.iam]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-oidc"
  display_name                       = "GitHub OIDC"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  attribute_condition = "assertion.repository == '${var.github_repo_owner_name}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  depends_on = [google_iam_workload_identity_pool.github]
}

# ── CI Service Account ────────────────────────────────────────────────────────

resource "google_service_account" "ci_deploy" {
  project      = var.project_id
  account_id   = "ci-deploy"
  display_name = "CI Deploy (GitHub Actions)"
}

# Allow the WIF pool to impersonate this SA
resource "google_service_account_iam_member" "ci_deploy_wif" {
  service_account_id = google_service_account.ci_deploy.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repo_owner_name}"
}

# ── IAM roles for the CI service account ──────────────────────────────────────

locals {
  ci_roles = [
    "roles/compute.admin",                   # reset VM
    "roles/secretmanager.admin",             # manage secrets
    "roles/iam.serviceAccountUser",          # attach SAs to resources
    "roles/storage.admin",                   # terraform state in GCS
    "roles/dns.admin",                       # manage DNS records
    "roles/resourcemanager.projectIamAdmin", # manage IAM bindings
    "roles/serviceusage.serviceUsageAdmin",  # enable/disable APIs
  ]
}

resource "google_project_iam_member" "ci_deploy" {
  for_each = toset(local.ci_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.ci_deploy.email}"
}

# The TF state bucket lives in the production project.  When this stack runs
# for staging, the project-level storage.admin above only covers staging
# buckets, so we need an explicit bucket-level grant for the shared state
# bucket.
resource "google_storage_bucket_iam_member" "ci_deploy_state_bucket" {
  bucket = var.tf_state_bucket
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.ci_deploy.email}"
}
