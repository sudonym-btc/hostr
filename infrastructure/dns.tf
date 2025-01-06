
resource "google_project_service" "dns" {
  project    = google_project.project.project_id
  service    = "dns.googleapis.com"
  depends_on = [google_project.project]
}

resource "google_dns_managed_zone" "main" {
  name     = "main-zone"
  dns_name = "${var.domain_name}."
  project  = google_project.project.project_id

  depends_on = [google_project_service.dns]
}
# Cannot hardcode NS as managed zone gets assigned authoritative NS on boot
# resource "google_dns_record_set" "ns" {
#   name         = "${var.domain_name}." # Root domain
#   type         = "NS"
#   ttl          = 300
#   managed_zone = google_dns_managed_zone.main.name
#   rrdatas = [
#     "ns-cloud-d1.googledomains.com.",
#     "ns-cloud-d2.googledomains.com.",
#     "ns-cloud-d3.googledomains.com.",
#     "ns-cloud-d4.googledomains.com."
#   ]
# }

resource "google_dns_record_set" "mx" {
  name         = "${var.domain_name}." # Root domain
  type         = "MX"
  ttl          = 300
  managed_zone = google_dns_managed_zone.main.name
  rrdatas = [
    "1 aspmx.l.google.com.",
    "5 alt1.aspmx.l.google.com.",
    "5 alt2.aspmx.l.google.com.",
    "10 alt3.aspmx.l.google.com."
  ]
  depends_on = [google_dns_managed_zone.main, google_project.project]
}

resource "google_compute_address" "static_ip" {
  name       = "static-ip"
  region     = var.region
  depends_on = [google_project.project]
}
resource "google_dns_record_set" "relay" {
  name         = "relay.${var.domain_name}."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.main.name
  rrdatas      = [google_compute_address.static_ip.address]
  depends_on   = [google_compute_address.static_ip]

}

# resource "google_dns_record_set" "mx" {
#   type         = "MX"
#   name         = "${var.domain_name}."
#   ttl          = 300
#   managed_zone = google_dns_managed_zone.main.name
#   rrdatas      = ["aspmx.l.google.com."]
# }
# resource "google_dns_record_set" "mx_1" {
#   type         = "MX"
#   name         = "${var.domain_name}."
#   ttl          = 300
#   managed_zone = google_dns_managed_zone.main.name
#   rrdatas      = ["alt1.aspmx.l.google.com."]
# }
