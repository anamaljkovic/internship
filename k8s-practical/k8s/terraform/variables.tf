variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "europe-west3"
}

variable "zone" {
  description = "GCP zone (zonal cluster keeps cost low)"
  type        = string
  default     = "europe-west3-a"
}

variable "network_name" {
  description = "VPC name"
  type        = string
  default     = "petclinic-vpc"
}

variable "subnet_cidr" {
  description = "Primary subnet range"
  type        = string
  default     = "10.10.0.0/20"
}

variable "pods_cidr" {
  description = "Secondary range for pods"
  type        = string
  default     = "10.40.0.0/16"
}

variable "services_cidr" {
  description = "Secondary range for services"
  type        = string
  default     = "10.50.0.0/20"
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
  default     = "petclinic-cluster"
}

variable "node_count" {
  description = "Number of nodes in the node pool"
  type        = number
  default     = 2
}

variable "machine_type" {
  description = "Node machine type"
  type        = string
  default     = "e2-standard-2"
}