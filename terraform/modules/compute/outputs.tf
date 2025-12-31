output "instance_name" {
  description = "Instance name"
  value       = google_compute_instance.vm.name
}

output "instance_id" {
  description = "Instance ID"
  value       = google_compute_instance.vm.instance_id
}

output "external_ip" {
  description = "External IP address"
  value       = google_compute_instance.vm.network_interface[0].access_config[0].nat_ip
}

output "internal_ip" {
  description = "Internal IP address"
  value       = google_compute_instance.vm.network_interface[0].network_ip
}