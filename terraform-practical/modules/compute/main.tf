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


resource "google_compute_instance_template" "web_template" {
  name_prefix  = "web-tmpl-"
  machine_type = var.machine_type
  tags         = ["web"]

  disk {
    source_image = google_compute_image.baked_image.self_link
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network    = var.network_self_link
    subnetwork = var.subnet_self_link
  }

    metadata_startup_script = var.startup_script

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_health_check" "web_health_check" {
  name                = "web-health-check"
    region              = var.region
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = var.app_port
    request_path = "/"
  }
}

resource "google_compute_region_instance_group_manager" "web_igm" {
  name               = "web-mig"
  region             = var.region
  base_instance_name = "web"
  target_size        = var.instance_count

  version {
    instance_template = google_compute_instance_template.web_template.id
  }

  named_port {
    name = "http"
    port = var.app_port
  }

  auto_healing_policies {
    health_check      = google_compute_region_health_check.web_health_check.id
    initial_delay_sec = 60
  }
}

resource "google_compute_region_backend_service" "web_backend" {
  name                  = "web-backend-service"
  region                = var.region
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  timeout_sec           = 10
  health_checks         = [google_compute_region_health_check.web_health_check.id]

  backend {
    group           = google_compute_region_instance_group_manager.web_igm.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

resource "google_compute_region_security_policy" "web_policy" {
  provider    = google-beta
  name        = "web-security-policy"
  region      = var.region
  description = "Restricts backend access to allowed IP ranges"
  type        = "CLOUD_ARMOR"
}

resource "google_compute_region_security_policy_rule" "default_rule" {
  provider        = google-beta
  region          = var.region
  security_policy = google_compute_region_security_policy.web_policy.name
  description     = "default rule"
  priority        = 2147483647
  action           = "deny(403)"

  match {
    versioned_expr = "SRC_IPS_V1"
    config {
      src_ip_ranges = ["*"]
    }
  }
}

resource "google_compute_region_security_policy_rule" "allow_configured_ranges" {
  provider    = google-beta
  region           = var.region
  security_policy  = google_compute_region_security_policy.web_policy.name
  description      = "allow configured IP ranges"
  priority         = 1000
  action           = "allow"

  match {
    versioned_expr = "SRC_IPS_V1"
    config {
      src_ip_ranges = var.allowed_http_ranges
    }
  }
}

resource "null_resource" "attach_security_policy" {
  triggers = {
    backend_service_id = google_compute_region_backend_service.web_backend.id
    security_policy_id = google_compute_region_security_policy.web_policy.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      gcloud compute backend-services update ${google_compute_region_backend_service.web_backend.name} \
        --region=${var.region} \
        --security-policy=${google_compute_region_security_policy.web_policy.name} \
        --project=${var.project_id}
    EOT
  }

  depends_on = [
    google_compute_region_backend_service.web_backend,
    google_compute_region_security_policy.web_policy,
    google_compute_region_security_policy_rule.allow_configured_ranges,
    google_compute_region_security_policy_rule.default_rule
  ]
}


resource "google_compute_address" "lb_ip" {
  name         = "web-lb-ip"
  region       = var.region
  address_type = "EXTERNAL"
}

resource "google_compute_region_url_map" "web_url_map" {
  name            = "web-url-map"
  region          = var.region
  default_service = google_compute_region_backend_service.web_backend.id
}

resource "google_compute_region_target_http_proxy" "web_http_proxy" {
  name    = "web-http-proxy"
  region  = var.region
  url_map = google_compute_region_url_map.web_url_map.id
}

resource "google_compute_forwarding_rule" "web_forwarding_rule" {
  name                  = "web-forwarding-rule"
  region                = var.region
  ip_address            = google_compute_address.lb_ip.address
  ip_protocol           = "TCP"
  port_range            = tostring(var.app_port)
  target                = google_compute_region_target_http_proxy.web_http_proxy.id
  load_balancing_scheme = "EXTERNAL_MANAGED"
  network               = var.network_self_link
}