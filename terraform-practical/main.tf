
module "network" {
  source = "./modules/network"

  network_name        = var.network_name
  subnet_cidr         = var.subnet_cidr
  region              = var.region
  allowed_ssh_ranges  = var.allowed_ssh_ranges
  allowed_http_ranges = var.allowed_http_ranges
  app_port            = var.app_port
}