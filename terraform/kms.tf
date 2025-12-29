# =============================================================================
# KMS Resources - MANUAL (No gestionados por Terraform)
# =============================================================================
# Los keyrings y claves KMS se crean manualmente porque:
# 1. Son recursos permanentes que NUNCA se eliminan
# 2. terraform destroy no debe afectarlos
# 3. Práctica empresarial estándar
#
# Keyring: project02-keyring (us-central1)
# Claves:
#   - data-encryption-key (ENCRYPT_DECRYPT, rotación 90 días)
#   - artifact-signing-key (ASYMMETRIC_SIGN, RSA 4096)
# =============================================================================

# Data sources para referenciar recursos KMS existentes
data "google_kms_key_ring" "main" {
  name     = "project02-keyring"
  location = var.region
}

data "google_kms_crypto_key" "data_encryption" {
  name     = "data-encryption-key"
  key_ring = data.google_kms_key_ring.main.id
}

data "google_kms_crypto_key" "artifact_signing" {
  name     = "artifact-signing-key"
  key_ring = data.google_kms_key_ring.main.id
}