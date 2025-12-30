variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "vpc_name" {
  description = "VPC network name"
  type        = string
}

variable "routing_mode" {
  description = "VPC routing mode"
  type        = string
  default     = "REGIONAL"
}

variable "subnets" {
  description = "List of subnets to create"
  type = list(object({
    name                  = string
    region                = string
    cidr                  = string
    private_google_access = bool
  }))
  default = []
}

variable "firewall_rules" {
  description = "List of firewall rules"
  type = list(object({
    name      = string
    direction = string
    priority  = number
    ranges    = list(string)
    allow = list(object({
      protocol = string
      ports    = list(string)
    }))
  }))
  default = []
}