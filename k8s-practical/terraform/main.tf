module "network" {
  source = "./modules/network"

  network_name  = var.network_name
  region        = var.region
  subnet_cidr   = var.subnet_cidr
  pods_cidr     = var.pods_cidr
  services_cidr = var.services_cidr
}

module "gke" {
  source = "./modules/gke"

  project_id          = var.project_id
  cluster_name        = var.cluster_name
  zone                = var.zone
  network_self_link   = module.network.network_self_link
  subnet_self_link    = module.network.subnet_self_link
  pods_range_name     = module.network.pods_range_name
  services_range_name = module.network.services_range_name
  node_count          = var.node_count
  machine_type        = var.machine_type
}