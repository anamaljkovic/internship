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

resource "google_compute_firewall" "allow_proxy_subnet" {
  name    = "${var.network_name}-allow-proxy-subnet"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = [tostring(var.app_port)]
  }

  source_ranges = [google_compute_subnetwork.proxy_only_subnet.ip_cidr_range]
  target_tags   = ["web"]
}

resource "google_compute_router" "router" {
  name    = "${var.network_name}-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.network_name}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_subnetwork" "proxy_only_subnet" {
  name          = "${var.network_name}-proxy-only"
  ip_cidr_range = "10.20.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

