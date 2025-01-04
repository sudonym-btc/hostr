provider "kubernetes" {
  host                   = format("https://%s", google_container_cluster.default.endpoint)
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.default.master_auth[0].cluster_ca_certificate)
}

resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  namespace  = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"

  create_namespace = true

  set {
    name  = "controller.service.annotations.networking\\.gke\\.io/static-ip"
    value = google_compute_address.static_ip.address
  }

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }
  set {
    name  = "controller.service.loadBalancerIP"
    value = google_compute_address.static_ip.address
  }

  set {
    name  = "controller.ingressClassResource.name"
    value = "nginx"
  }

  set {
    name  = "controller.ingressClassResource.controllerValue"
    value = "k8s.io/ingress-nginx"
  }
}
resource "null_resource" "wait_for_certificate" {
  provisioner "local-exec" {
    command = <<EOT
      while ! kubectl get secret hostr-network-tls -n default; do
        echo "Waiting for certificate to be issued..."
        sleep 1
      done
    EOT
  }
}

resource "kubernetes_ingress_v1" "relay" {
  metadata {
    name = "${google_project.project.name}-ingress"
    annotations = {
      "kubernetes.io/ingress.class"                    = "nginx" # Use the appropriate ingress class
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"  # Redirect HTTP to HTTPS
      "cert-manager.io/issue-temporary-certificate"    = "false"
      "nginx.ingress.kubernetes.io/proxy-read-timeout" = "3600" # Allow long-lived WebSocket connections
      "nginx.ingress.kubernetes.io/proxy-send-timeout" = "3600"
      "nginx.ingress.kubernetes.io/proxy-buffering"    = "off" # Disable buffering for WebSocket
    }
  }

  spec {
    rule {
      host = "relay.${var.domain_name}"

      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.relay.metadata[0].name
              port {
                number = 443
              }
            }
          }
        }
      }
    }
    tls {
      hosts       = ["*.${var.domain_name}"]
      secret_name = "hostr-network-tls" # Replace with your desired secret name
    }
  }

  depends_on = [helm_release.nginx_ingress, kubernetes_manifest.certificate, null_resource.wait_for_certificate]
}

resource "google_service_account" "relay_service_account" {
  account_id   = "relay-service-account"
  display_name = "Service Account for Nostr Relay Pod"
}

resource "google_project_iam_member" "relay_secret_access" {
  project = google_project.project.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.relay_service_account.email}"
}
resource "google_project_iam_member" "relay_service_account_token_creator" {
  project = google_project.project.project_id
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_service_account.relay_service_account.email}"
}

resource "google_project_iam_member" "relay_workload_identity_user" {
  project = google_project.project.project_id
  role    = "roles/iam.workloadIdentityUser"
  member  = "serviceAccount:${google_service_account.relay_service_account.email}"
}


resource "kubernetes_service_account" "relay_service_account" {
  metadata {
    name      = "relay-service-account"
    namespace = "default"
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.relay_service_account.email
    }
  }
}

resource "local_file" "relay_config" {
  content = templatefile("${path.module}/relay/config.template.toml", {
    relay_url  = var.domain_name
    relay_name = var.domain_name
  })
  filename = "${path.module}/relay/${var.env}.config.toml"
}

resource "kubernetes_deployment_v1" "relay" {
  metadata {
    name = "${google_project.project.name}-relay"
  }

  spec {

    selector {
      match_labels = {
        app = "relay"
      }

    }

    template {


      metadata {
        labels = {
          app = "relay"
        }
      }

      spec {

        service_account_name = kubernetes_service_account.relay_service_account.metadata[0].name

        # Init container to append the private key to config.toml
        init_container {
          name    = "append-private-key"
          image   = "google/cloud-sdk:latest"
          command = ["sleep", "infinity"]

          # command = ["/bin/bash", "-c"]
          #     args = [
          #       <<EOT
          # SECRET=$(cat secret/secret.data)
          # echo SECRET
          # cp config/config_draft.toml workdir/config.toml
          # ls 
          # ls workdir
          # echo "Listing done"
          # echo "secret_key = '$SECRET'" >> workdir/config.toml
          #       EOT
          #     ]


          env {
            name  = "PROJECT_ID"
            value = google_project.project.project_id
          }

          volume_mount {
            name       = "config-volume"
            mount_path = "/config"
          }
          volume_mount {
            name       = "workdir"
            mount_path = "/workdir"
          }

          # volume_mount {
          #   mount_path = "/var/run/secrets/kubernetes.io/serviceaccount"
          #   name       = "kube-api-access"
          #   read_only  = true
          # }
          security_context {
            run_as_group               = 2000
            run_as_user                = 1000
            allow_privilege_escalation = false
            privileged                 = false
            read_only_root_filesystem  = false
            run_as_non_root            = true
            capabilities {
              add  = []
              drop = ["NET_RAW"]
            }
          }
        }
        container {
          image = "scsibug/nostr-rs-relay:latest" # Updated image
          name  = "nostr-relay-container"
          args  = ["--db", "workdir/config.toml"]


          port {
            container_port = 8080
            name           = "nostr-relay"
          }
          volume_mount {
            name       = "workdir"
            mount_path = "/workdir"
          }

          volume_mount {
            name       = "data-volume"
            mount_path = "/usr/src/app/db" # Directory to mount the persistent disk
          }

          security_context {
            allow_privilege_escalation = false
            privileged                 = false
            read_only_root_filesystem  = false

            capabilities {
              add  = []
              drop = ["NET_RAW"]
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = "nostr-relay"
            }

            initial_delay_seconds = 3
            period_seconds        = 3
          }
        }

        volume {
          name = "config-volume"
          config_map {
            name = kubernetes_config_map.relay_config.metadata[0].name
          }
        }
        volume {
          name = "workdir"
          empty_dir {}
        }

        volume {
          name = "data-volume"
          persistent_volume_claim {
            claim_name = "relay-data-pvc" # Reference the PersistentVolumeClaim, do not use hyperlink reference or the pod will not attempt to bind so pvc will not bind
          }
        }

        # volume {
        #   name = "kube-api-access"
        #   projected {
        #     sources {
        #       service_account_token {
        #         path = "token"
        #       }
        #       config_map {
        #         name = "kube-root-ca.crt"
        #         items {
        #           key  = "ca.crt"
        #           path = "ca.crt"
        #         }
        #       }
        #       downward_api {
        #         items {
        #           path = "namespace"
        #           field_ref {
        #             field_path = "metadata.namespace"
        #           }
        #         }
        #       }
        #     }
        #   }
        # }

        security_context {
          run_as_non_root = true

          seccomp_profile {
            type = "RuntimeDefault"
          }
        }

        toleration {
          effect   = "NoSchedule"
          key      = "kubernetes.io/arch"
          operator = "Equal"
          value    = "amd64"
        }
      }
    }
  }
}

resource "google_compute_disk" "relay_data_disk" {
  name = "relay-data-disk"
  type = "pd-standard" # Choose pd-standard or pd-ssd
  zone = google_container_cluster.default.location
  size = 10 # Size in GB
}

resource "kubernetes_persistent_volume_v1" "relay_data_pv" {
  metadata {
    name = "relay-data-pv"
    labels = {
      name = "relay-data-pv"
    }
  }

  spec {
    capacity = {
      storage = "10Gi"
    }

    access_modes = ["ReadWriteOnce"]

    persistent_volume_source {
      gce_persistent_disk {
        pd_name = google_compute_disk.relay_data_disk.name
        fs_type = "ext4"
      }
    }
    storage_class_name = "" # No StorageClass

    persistent_volume_reclaim_policy = "Retain"
  }
}

resource "kubernetes_persistent_volume_claim_v1" "relay_data_pvc" {
  metadata {
    name      = "relay-data-pvc"
    namespace = "default"
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = ""
    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }
  depends_on = [kubernetes_persistent_volume_v1.relay_data_pv]
}

resource "kubernetes_config_map" "relay_config" {
  metadata {
    name = "relay-config-map"
  }

  data = {
    "config_draft.toml" = file("${path.module}/relay/${var.env}.toml") # Path to your config.toml
  }
}

resource "kubernetes_service_v1" "relay" {
  metadata {
    name = "${google_project.project.name}-loadbalancer"
  }

  spec {
    selector = {
      app = kubernetes_deployment_v1.relay.spec[0].selector[0].match_labels.app
    }

    port {
      port        = 443
      target_port = 8080
    }

    type = "ClusterIP" # Change from LoadBalancer to ClusterIP
  }

  depends_on = [time_sleep.wait_service_cleanup]
}

# Provide time for Service cleanup
resource "time_sleep" "wait_service_cleanup" {
  depends_on = [google_container_cluster.default]

  destroy_duration = "180s"
}
