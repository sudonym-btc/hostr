# GKE cluster


resource "google_project_service" "container" {
  project = google_project.project.project_id
  service = "container.googleapis.com"
}

data "google_container_engine_versions" "gke_version" {
  location       = var.region
  version_prefix = "1.27."

  depends_on = [
    google_project_service.container,
  ]
}


resource "google_container_cluster" "default" {
  name     = "${google_project.project.name}-gke"
  location = var.region

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.default.name

  deletion_protection = false

  # Enabling Autopilot for this cluster
  enable_autopilot = true

  depends_on = [
    google_project_service.container,
  ]
  lifecycle {
    ignore_changes = [
      # Ignore changes to node pools, etc.
      initial_node_count,
      node_config,
      node_pool,
      ip_allocation_policy,
      master_authorized_networks_config,
      # Ignore changes to tags and labels
      resource_labels,
      # Ignore changes to maintenance policies
      maintenance_policy,
      # Ignore changes to the release channel
      release_channel,
      # Ignore changes to network config
      network_policy,
      private_cluster_config,
    ]
  }
}

output "gke_cluster_name" {
  value = google_container_cluster.default.name
}

output "gke_cluster_endpoint" {
  value = google_container_cluster.default.endpoint
}
