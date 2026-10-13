variable "project_id" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "zone" {
  type = string
}

variable "network_self_link" {
  type = string
}

variable "subnet_self_link" {
  type = string
}

variable "pods_range_name" {
  type = string
}

variable "services_range_name" {
  type = string
}

variable "node_count" {
  type = number
}

variable "machine_type" {
  type = string
}