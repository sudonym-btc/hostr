variable "env" {
  description = "The environment of the project."
  type        = string
}

variable "project_name" {
  description = "The name of the project."
  type        = string
}

variable "org_id" {
  description = "The organization ID."
  type        = string
}

variable "billing_account" {
  description = "The billing account ID."
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

variable "gke_num_nodes" {
  default     = 1
  description = "number of gke nodes"
}

variable "relay_machine_type" {
  default     = "n1-standard-2" //n1-standard-1
  description = "machine type for gke nodes"
}
