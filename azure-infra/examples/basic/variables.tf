variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID."
  sensitive   = true
}

variable "tenant_id" {
  type        = string
  description = "The Azure tenant ID."
  sensitive   = true
}

variable "client_id" {
  type        = string
  description = "The service principal client (application) ID."
  sensitive   = true
}

variable "client_secret" {
  type        = string
  description = "The service principal client secret."
  sensitive   = true
}
