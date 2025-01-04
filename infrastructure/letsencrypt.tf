// Create a Kubernetes namespace for cert-manager
resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}
// Configure the Helm provider to interact with the Kubernetes cluster
provider "helm" {
  kubernetes {
    host                   = format("https://%s", google_container_cluster.default.endpoint)
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.default.master_auth[0].cluster_ca_certificate)
  }
}

// Create a Google Service Account for Let's Encrypt DNS validation
resource "google_service_account" "letsencrypt" {
  account_id   = "letsencrypt-dns"
  display_name = "Service Account for Let's Encrypt DNS Validation"
}

// Assign the DNS Admin role to the Google Service Account
resource "google_project_iam_member" "letsencrypt_dns" {
  project = google_project.project.project_id
  role    = "roles/dns.admin"
  member  = "serviceAccount:${google_service_account.letsencrypt.email}"
}

// Grant the Kubernetes Service Account permission to impersonate the Google Service Account
resource "google_service_account_iam_binding" "workload_identity_binding" {
  service_account_id = google_service_account.letsencrypt.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${google_project.project.project_id}.svc.id.goog[cert-manager/letsencrypt-dns]"
  ]
}

// Assign the DNS Admin role to the Google Service Account
resource "google_project_iam_binding" "dns_admin_binding" {
  project = google_project.project.project_id
  role    = "roles/dns.admin"

  members = [
    "serviceAccount:${google_service_account.letsencrypt.email}"
  ]
}

// Deploy cert-manager using Helm
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name


  set {
    name  = "crds.enabled"
    value = "true"
  }
  set {
    name  = "serviceAccount.name"
    value = "letsencrypt-dns"
  }

  set {
    name  = "serviceAccount.annotations.iam\\.gke\\.io/gcp-service-account"
    value = google_service_account.letsencrypt.email
  }

  depends_on = [kubernetes_namespace.cert_manager]
}

// Create a ClusterIssuer resource for Let's Encrypt
resource "kubernetes_manifest" "letsencrypt_issuer" {
  depends_on = [helm_release.cert_manager]
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "ClusterIssuer"
    "metadata" = {
      "name" = "letsencrypt"
    }
    "spec" = {
      "acme" = {
        "server" = "https://acme-v02.api.letsencrypt.org/directory"
        "email"  = "admin@hostr.network"
        "privateKeySecretRef" = {
          "name" = "letsencrypt-private-key"
        }
        "solvers" = [
          {
            "dns01" = {
              "cloudDNS" = {
                "project" = google_project.project.project_id
              }
            }
          }
        ]
      }
    }
  }
}

// Create a Certificate resource for the domain
resource "kubernetes_manifest" "certificate" {
  depends_on = [helm_release.cert_manager]

  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "certificate"
      "namespace" = "default"
    }
    "spec" = {
      "dnsNames"   = ["*.${var.domain_name}"]
      "secretName" = "hostr-network-tls"
      "issuerRef" = {
        "name" = "letsencrypt"
        "kind" = "ClusterIssuer"
      }
    }
  }
}
