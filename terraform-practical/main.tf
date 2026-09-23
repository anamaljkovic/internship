
module "network" {
  source = "./modules/network"

  network_name        = var.network_name
  subnet_cidr         = var.subnet_cidr
  region              = var.region
  allowed_ssh_ranges  = var.allowed_ssh_ranges
  allowed_http_ranges = var.allowed_http_ranges
  app_port            = var.app_port
}

module "compute" {
  source = "./modules/compute"

  zone              = var.zone
  network_self_link = module.network.network_self_link
  subnet_self_link  = module.network.subnet_self_link
  machine_type      = var.machine_type
  startup_script    = file("${path.module}/scripts/startup.sh")
}