resource "google_project_service" "compute" {
  project = google_project.project.project_id
  service = "compute.googleapis.com"
}

# VPC
resource "google_compute_network" "vpc" {
  project                 = google_project.project.project_id
  name                    = "${google_project.project.name}-vpc"
  auto_create_subnetworks = false

  depends_on = [
    google_project_service.compute,
  ]
}

# Subnet
resource "google_compute_subnetwork" "default" {
  project = google_project.project.project_id
  name          = "${google_project.project.name}-subnet"
  region        = var.region
  network       = google_compute_network.vpc.name

  ip_cidr_range = "10.0.0.0/16"

  stack_type       = "IPV4_IPV6"
  ipv6_access_type = "EXTERNAL" # Change to "EXTERNAL" if creating an external loadbalancer

  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "10.1.0.0/22"
  }

  secondary_ip_range {
    range_name    = "pod-ranges"
    ip_cidr_range = "10.2.0.0/22"
  }
}