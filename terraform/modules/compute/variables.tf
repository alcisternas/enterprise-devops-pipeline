variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "instance_name" {
  description = "VM instance name"
  type        = string
}

variable "machine_type" {
  description = "Machine type"
  type        = string
  default     = "e2-medium"
}

variable "zone" {
  description = "GCP zone"
  type        = string
}

variable "image" {
  description = "Boot disk image"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 30
}

variable "network" {
  description = "VPC network"
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "VPC subnetwork"
  type        = string
  default     = null
}

variable "startup_script" {
  description = "Startup script content"
  type        = string
  default     = ""
}

variable "service_account_email" {
  description = "Service account email"
  type        = string
  default     = null
}

variable "network_tags" {
  description = "Network tags"
  type        = list(string)
  default     = []
}

variable "create_firewall" {
  description = "Create firewall rule"
  type        = bool
  default     = false
}

variable "allowed_source_ranges" {
  description = "Allowed source IP ranges for firewall"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}