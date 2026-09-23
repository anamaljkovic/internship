resource "google_compute_instance" "temp_vm" {
  name         = "temp-web-builder"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["ssh", "web"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
    }
  }

  network_interface {
    network    = var.network_self_link
    subnetwork = var.subnet_self_link
    access_config {} 
  }

  metadata_startup_script = var.startup_script

  allow_stopping_for_update = true
}