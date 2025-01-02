
# GKE cluster


resource "google_project_service" "container" {
  project = google_project.project.project_id
  service = "container.googleapis.com"
}

data "google_container_engine_versions" "gke_version" {
  location = var.region
  version_prefix = "1.27."

  depends_on = [
    google_project_service.container,
  ]
}


resource "google_container_cluster" "default" {
  name     = "${google_project.project.name}-gke"
  location = var.region
  enable_l4_ilb_subsetting = true

  # Enable advanced datapath
  datapath_provider = "ADVANCED_DATAPATH"

  deletion_protection = false

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  initial_node_count       = 1

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.default.name

  ip_allocation_policy {
    stack_type                    = "IPV4_IPV6"
    services_secondary_range_name = google_compute_subnetwork.default.secondary_ip_range[0].range_name
    cluster_secondary_range_name  = google_compute_subnetwork.default.secondary_ip_range[1].range_name
  }

  default_max_pods_per_node = 10


  depends_on = [
    google_project_service.container,
  ]
}
# Separately Managed Node Pool
resource "google_container_node_pool" "default" {
  name       = google_container_cluster.default.name
  location   = var.region
  cluster    = google_container_cluster.default.name
  
  version = data.google_container_engine_versions.gke_version.latest_master_version
  node_count = var.gke_num_nodes

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env =  google_project.project.name
    }

    # preemptible  = true
    machine_type = "n1-standard-1"
    tags         = ["gke-node", "${google_project.project.name}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  depends_on = [
    google_container_cluster.default,
  ]
}

output "gke_cluster_name" {
  value = google_container_cluster.default.name
}

output "gke_cluster_endpoint" {
  value = google_container_cluster.default.endpoint
}