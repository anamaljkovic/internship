output "load_balancer_ip" {
  description = "Open this in a browser or curl it to test the HA website"
  value       = module.compute.load_balancer_ip
}