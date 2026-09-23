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

resource "null_resource" "wait_and_stop" {
  triggers = {
    instance_id = google_compute_instance.temp_vm.instance_id
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      echo "waiting for provisioning to complete on temp vm"
      for i in $(seq 1 30); do
        if gcloud compute instances get-serial-port-output ${google_compute_instance.temp_vm.name} \
             --zone=${var.zone} --project=${var.project_id} 2>/dev/null | grep -q provisioning_complete; then
          break
        fi
        sleep 10
      done
      echo "stopping temp vm before image capture"
      gcloud compute instances stop ${google_compute_instance.temp_vm.name} \
        --zone=${var.zone} --project=${var.project_id}
    EOT
  }

  depends_on = [google_compute_instance.temp_vm]
}

resource "google_compute_image" "baked_image" {
  name        = var.image_name
  source_disk = google_compute_instance.temp_vm.boot_disk[0].source

  depends_on = [null_resource.wait_and_stop]
}

