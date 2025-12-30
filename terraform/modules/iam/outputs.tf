output "email" {
  description = "Service account email"
  value       = google_service_account.sa.email
}

output "id" {
  description = "Service account ID"
  value       = google_service_account.sa.id
}