output "project_id" {
  description = "GCP Project ID"
  value       = var.project_id
}

output "region" {
  description = "GCP Region"
  value       = var.region
}

# KMS Outputs
output "kms_keyring_id" {
  description = "KMS Keyring ID"
  value       = data.google_kms_key_ring.main.id
}

output "kms_data_encryption_key_id" {
  description = "KMS Data Encryption Key ID"
  value       = data.google_kms_crypto_key.data_encryption.id
}

output "kms_artifact_signing_key_id" {
  description = "KMS Artifact Signing Key ID"
  value       = data.google_kms_crypto_key.artifact_signing.id
}

# Storage Outputs
output "encrypted_bucket_name" {
  description = "Encrypted bucket name with CMEK"
  value       = google_storage_bucket.encrypted_data.name
}

output "encrypted_bucket_url" {
  description = "Encrypted bucket URL"
  value       = google_storage_bucket.encrypted_data.url
}

# Artifact Registry Outputs
output "artifact_registry_id" {
  description = "Artifact Registry repository ID"
  value       = google_artifact_registry_repository.containers.id
}

output "artifact_registry_url" {
  description = "URL for push/pull images"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/containers"
}

# IAM Outputs
output "cloud_run_sa_email" {
  description = "Cloud Run Service Account email"
  value       = google_service_account.cloud_run_sa.email
}