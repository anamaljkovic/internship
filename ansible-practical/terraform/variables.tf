variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "europe-central2"
}

variable "zone" {
  type    = string
  default = "europe-central2-a"
}

variable "machine_type" {
  type    = string
  default = "e2-small"
}

variable "allowed_ssh_ranges" {
  type = list(string)
}

variable "allowed_app_ranges" {
  type = list(string)
}

variable "ssh_public_key_path" {
  description = "Path to public key"
  type        = string
  default     = "~/.ssh/ansible-gcp.pub"
}

variable "ssh_user" {
  type    = string
  default = "ansible"
}