
resource "google_compute_address" "static_ip" {
  project    = var.project_id
  name       = "static-ip"
  region     = var.region
  depends_on = [google_project_service.compute]
}

resource "google_project_service" "dns" {
  project = var.project_id
  service = "dns.googleapis.com"
}

data "google_dns_managed_zone" "app_zone" {
  project = var.project_id
  name    = var.managed_zone_name

  depends_on = [google_project_service.dns]
}

resource "google_dns_record_set" "relay" {
  name         = "relay.${var.domain_name}."
  type         = "A"
  ttl          = 300
  project      = var.project_id
  managed_zone = data.google_dns_managed_zone.app_zone.name
  rrdatas      = [google_compute_address.static_ip.address]

  depends_on = [google_compute_address.static_ip]
}

resource "google_dns_record_set" "blossom" {
  name         = "blossom.${var.domain_name}."
  type         = "A"
  ttl          = 300
  project      = var.project_id
  managed_zone = data.google_dns_managed_zone.app_zone.name
  rrdatas      = [google_compute_address.static_ip.address]

  depends_on = [google_compute_address.static_ip]
}
