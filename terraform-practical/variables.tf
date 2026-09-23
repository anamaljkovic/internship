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

variable "allowed_ssh_ranges" {
  description = "IP ranges allowed to SSH into instances"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_http_ranges" {
  description = "IP ranges allowed to reach the load balancer"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "app_port" {
  description = "Port the web server listens on"
  type        = number
  default     = 80
}

variable "machine_type" {
  description = "Machine for temp VM"
  type        = string
  default     = "e2-medium"
}

variable "image_name" {
  description = "Name of the custom image baked from the temp VM"
  type        = string
  default     = "web-image"
}
