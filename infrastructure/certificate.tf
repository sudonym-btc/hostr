resource "google_project_service" "certificatemanager" {
  project = google_project.project.project_id
  service = "certificatemanager.googleapis.com"
}