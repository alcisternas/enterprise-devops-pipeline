# =============================================================================
# Cloud Run - Preparación para CMEK
# =============================================================================
# Nota: El servicio Cloud Run se desplegará en sesiones posteriores (S13+)
# cuando tengamos una imagen construida y firmada.
# 
# Este archivo documenta la configuración CMEK que se aplicará:
#
# resource "google_cloud_run_v2_service" "app" {
#   name     = "demo-app"
#   location = var.region
#
#   template {
#     service_account = google_service_account.cloud_run_sa.email
#     
#     encryption_key_revocation_action = "SHUTDOWN"
#     encryption_key                   = data.google_kms_crypto_key.data_encryption.id
#
#     containers {
#       image = "${var.region}-docker.pkg.dev/${var.project_id}/containers/demo-app:latest"
#     }
#   }
# }
# =============================================================================

# Obtener Service Account de Cloud Run para permisos KMS
resource "google_project_service_identity" "cloud_run" {
  provider = google-beta
  project  = var.project_id
  service  = "run.googleapis.com"
}

# Permiso para que el agente de Cloud Run use la clave KMS
resource "google_kms_crypto_key_iam_member" "cloud_run_agent_kms" {
  crypto_key_id = data.google_kms_crypto_key.data_encryption.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.cloud_run.email}"
}