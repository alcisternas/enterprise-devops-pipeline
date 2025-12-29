# =============================================================================
# Artifact Registry - Repositorio de imagenes encriptado con CMEK
# =============================================================================

resource "google_artifact_registry_repository" "containers" {
  location      = var.region
  repository_id = "containers"
  description   = "Repositorio de imagenes de contenedores"
  format        = "DOCKER"

  kms_key_name = data.google_kms_crypto_key.data_encryption.id

  labels = {
    environment = "dev"
    managed_by  = "terraform"
    encryption  = "cmek"
  }
}