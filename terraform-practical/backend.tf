terraform {
  backend "gcs" {
    bucket = "gd-devops-ana-terraform-state"
    prefix = "terraform/internship"
  }
}