variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "repository_id" {
  description = "Artifact Registry repository ID"
  type        = string
}

variable "kms_key_name" {
  description = "KMS key for CMEK encryption"
  type        = string
  default     = null
}

variable "description" {
  description = "Repository description"
  type        = string
  default     = "Docker repository"
}