# =============================================================================
# IAM - Service Accounts
# =============================================================================

resource "google_service_account" "cloud_run_sa" {
  account_id   = "cloud-run-sa"
  display_name = "Cloud Run Service Account"
  description  = "Service Account para aplicaciones en Cloud Run"
}

# Permiso para que Cloud Run SA use la clave KMS
resource "google_kms_crypto_key_iam_member" "cloud_run_kms" {
  crypto_key_id = data.google_kms_crypto_key.data_encryption.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}