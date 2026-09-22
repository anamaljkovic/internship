resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.network_name}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_compute_firewall" "allow_ssh" {
  name = "${var.network_name}-allow-ssh"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports = ["22"]
  }
    source_ranges = var.allowed_ssh_ranges
    target_tags = ["ssh"]
}

resource "google_compute_firewall" "allow_lb_app_port" {
  name = "${var.network_name}-allow-lb-${var.app_port}"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = [tostring(var.app_port)]
  }
  source_ranges = var.allowed_http_ranges
  target_tags   = ["web"]
}

resource "google_compute_firewall" "allow_health_checks" {
  name    = "${var.network_name}-allow-health-checks"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = [tostring(var.app_port)]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["web"]
}