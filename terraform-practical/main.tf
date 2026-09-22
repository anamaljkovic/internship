
module "network" {
  source = "./modules/network"

  network_name = var.network_name
  subnet_cidr  = var.subnet_cidr
  region       = var.region
}