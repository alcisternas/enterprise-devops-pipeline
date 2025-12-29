# =============================================================================
# Cloud Storage - Bucket encriptado con CMEK
# =============================================================================

resource "google_storage_bucket" "encrypted_data" {
  name          = "${var.project_id}-encrypted-data"
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = data.google_kms_crypto_key.data_encryption.id
  }

  labels = {
    environment = "dev"
    managed_by  = "terraform"
    encryption  = "cmek"
  }
}