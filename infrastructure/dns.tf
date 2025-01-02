
resource "google_project_service" "dns" {
  project = google_project.project.project_id
  service = "dns.googleapis.com"
}

resource "google_dns_managed_zone" "main" {
    name     = "main-zone"
    dns_name = var.domain_name
    project  = google_project.project.project_id
}
  
resource "google_dns_record_set" "relay" {
  name         = "relay.${var.domain_name}"
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.main.name
  rrdatas      = [kubernetes_service_v1.relay.status.0.load_balancer.0.ingress.0.ip]
}
