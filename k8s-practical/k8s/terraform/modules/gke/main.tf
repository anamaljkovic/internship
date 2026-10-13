resource "google_container_cluster" "primary" {
  project  = var.project_id
  name     = var.cluster_name
  location = var.zone 

  network    = var.network_self_link
  subnetwork = var.subnet_self_link

  remove_default_node_pool = true
  initial_node_count       = 1

  deletion_protection = false

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }
}

resource "google_container_node_pool" "primary" {
  project    = var.project_id
  name       = "primary-pool"
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = var.machine_type
    disk_size_gb = 30
    disk_type    = "pd-balanced"
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}