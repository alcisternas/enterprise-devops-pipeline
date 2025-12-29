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