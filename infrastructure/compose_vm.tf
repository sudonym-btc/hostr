resource "google_project_service" "secretmanager" {
  project = google_project.project.project_id
  service = "secretmanager.googleapis.com"
}

resource "google_compute_firewall" "compose_public" {
  name    = "compose-public"
  project = google_project.project.project_id
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }

  source_ranges = var.compose_source_ranges
  target_tags   = ["hostr-compose"]
}

locals {
  compose_runtime_secret_names = [
    "ESCROW_PRIVATE_KEY",
    "BLOSSOM_DASHBOARD_PASSWORD",
  ]
}

resource "google_secret_manager_secret" "compose_runtime" {
  for_each  = toset(local.compose_runtime_secret_names)
  project   = google_project.project.project_id
  secret_id = each.value

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "compose_runtime_seed" {
  for_each = {
    for k, v in var.compose_runtime_secret_values :
    k => v
    if contains(local.compose_runtime_secret_names, k) && trimspace(v) != ""
  }

  secret      = google_secret_manager_secret.compose_runtime[each.key].id
  secret_data = each.value
}

resource "google_service_account" "compose_vm" {
  account_id   = "compose-vm"
  display_name = "Service Account for Docker Compose VM"
}

resource "google_project_iam_member" "compose_vm_secret_access" {
  project = google_project.project.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.compose_vm.email}"
}

resource "google_project_iam_member" "compose_vm_log_writer" {
  project = google_project.project.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.compose_vm.email}"
}

resource "google_compute_instance" "compose_vm" {
  name         = "${google_project.project.name}-compose"
  project      = google_project.project.project_id
  machine_type = var.compose_machine_type
  zone         = var.compose_zone
  tags         = ["hostr-compose"]

  boot_disk {
    initialize_params {
      image = "projects/debian-cloud/global/images/family/debian-12"
      size  = var.compose_boot_disk_size_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.default.id
    access_config {
      nat_ip = google_compute_address.static_ip.address
    }
  }

  service_account {
    email  = google_service_account.compose_vm.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = templatefile("${path.module}/templates/compose_startup.sh.tftpl", {
    repo_clone_url     = var.compose_repo_clone_url
    repo_branch        = var.compose_repo_branch
    default_target_env = var.env
    secret_names       = local.compose_runtime_secret_names
  })

  depends_on = [
    google_project_service.compute,
    google_project_service.secretmanager,
    google_project_iam_member.compose_vm_secret_access,
    google_compute_firewall.compose_public,
  ]
}
