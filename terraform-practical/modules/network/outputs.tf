output "network_id" {
  value = google_compute_network.vpc.id
}

output "network_self_link" {
  value = google_compute_network.vpc.self_link
}

output "subnet_id" {
  value = google_compute_subnetwork.subnet.id
}

output "subnet_self_link" {
  value = google_compute_subnetwork.subnet.self_link
}

output "nat_name" {
  value = google_compute_router_nat.nat.name
}

