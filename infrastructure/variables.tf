variable "env" {
  description = "The environment (staging or production)."
  type        = string
}

variable "project_name" {
  description = "Short project name used in resource naming."
  type        = string
}

variable "project_id" {
  description = "GCP project ID to deploy into."
  type        = string
}

variable "region" {
  description = "The region in which to provision resources."
  type        = string
  default     = "us-central1"
}

variable "domain_name" {
  description = "The domain name to be purchased."
  type        = string
}

variable "managed_zone_name" {
  description = "Existing Cloud DNS managed zone name in this environment project."
  type        = string
  default     = "main-zone"
}

variable "compose_machine_type" {
  description = "Machine type for the single Docker Compose VM."
  type        = string
  default     = "e2-standard-2"
}

variable "compose_zone" {
  description = "Zone for the Docker Compose VM."
  type        = string
  default     = "us-central1-a"
}

variable "compose_boot_disk_size_gb" {
  description = "Boot disk size (GB) for the Docker Compose VM."
  type        = number
  default     = 50
}

variable "compose_repo_clone_url" {
  description = "Git URL used by the VM to clone the hostr repo for docker compose deployment."
  type        = string
  default     = "https://github.com/sudonym-btc/hostr.git"
}

variable "compose_repo_branch" {
  description = "Git branch deployed on the VM."
  type        = string
  default     = "main"
}

variable "compose_source_ranges" {
  description = "Source CIDRs allowed to reach VM ports 22/80/443."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "compose_runtime_secret_values" {
  description = "Optional map to seed Secret Manager values (ESCROW_PRIVATE_KEY, BLOSSOM_DASHBOARD_PASSWORD)."
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "enable_maps_infra" {
  description = "Whether to manage Maps API services/keys in this stack. Disable for compose-only infra deploys."
  type        = bool
  default     = false
}
