variable "org_id" {
  description = "GCP organization ID."
  type        = string
}

variable "billing_account" {
  description = "GCP billing account ID."
  type        = string
}

variable "project_name" {
  description = "Base name for projects (produces <name>-staging-<hex>, <name>-production-<hex>)."
  type        = string
  default     = "hostr"
}

variable "region" {
  description = "Default GCP region."
  type        = string
  default     = "us-central1"
}

variable "domain" {
  description = "Root domain name."
  type        = string
  default     = "hostr.network"
}

variable "state_bucket_name" {
  description = "Globally unique GCS bucket name for Terraform remote state."
  type        = string
}

variable "state_bucket_location" {
  description = "GCS bucket location."
  type        = string
  default     = "US"
}

variable "mx_records" {
  description = "MX records for the root domain."
  type        = list(string)
  default = [
    "1 aspmx.l.google.com.",
    "5 alt1.aspmx.l.google.com.",
    "5 alt2.aspmx.l.google.com.",
    "10 alt3.aspmx.l.google.com.",
  ]
}
