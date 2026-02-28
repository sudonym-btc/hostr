resource "google_project_service" "compute" {
  project = var.project_id
  service = "compute.googleapis.com"
}

# VPC
resource "google_compute_network" "vpc" {
  project                 = var.project_id
  name                    = "${local.project_base_name}-vpc"
  auto_create_subnetworks = false

  depends_on = [
    google_project_service.compute,
  ]
}

# Subnet
resource "google_compute_subnetwork" "default" {
  project = var.project_id
  name    = "${local.project_base_name}-subnet"
  region  = var.region
  network = google_compute_network.vpc.name

  ip_cidr_range = "10.0.0.0/16"
}
