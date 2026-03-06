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

# ── Workload Identity Pool ────────────────────────────────────────────────────
# IAM APIs are enabled by the bootstrap project.

resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = "github-actions"
  display_name              = "GitHub Actions"
  description               = "OIDC pool for GitHub Actions CI/CD"
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

# ── CI Service Account (created by bootstrap) ────────────────────────────────
# The SA and its IAM role bindings live in the bootstrap project to avoid a
# chicken-and-egg problem: the SA needs permissions (e.g. serviceUsageConsumer)
# to refresh resources during `terraform plan`, but it cannot grant itself
# those permissions in the same apply that first requires them.

data "google_service_account" "ci_deploy" {
  account_id = "ci-deploy@${var.project_id}.iam.gserviceaccount.com"
}

# Allow the WIF pool to impersonate this SA
resource "google_service_account_iam_member" "ci_deploy_wif" {
  service_account_id = data.google_service_account.ci_deploy.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repo_owner_name}"
}
