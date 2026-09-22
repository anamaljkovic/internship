variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "europe-central2"
}

variable "zone" {
  description = "GCP zone for the temp VM"
  type        = string
  default     = "europe-central2-a"
}

variable "network_name" {
  description = "VPC name"
  type        = string
  default     = "ana-vpc"
}

variable "subnet_cidr" {
  description = "CIDR range for the subnet"
  type        = string
  default     = "10.10.0.0/24"
}
