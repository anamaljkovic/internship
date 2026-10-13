output "cluster_name" {
  value = module.gke.cluster_name
}

output "cluster_location" {
  value = module.gke.cluster_location
}

output "get_credentials_command" {
  description = "Run this to point kubectl at the new cluster"
  value       = "gcloud container clusters get-credentials ${module.gke.cluster_name} --zone ${module.gke.cluster_location} --project ${var.project_id}"
}