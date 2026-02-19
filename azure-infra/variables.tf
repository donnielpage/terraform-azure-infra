variable "name" {
  type        = string
  description = "The base name used to prefix all resources in the Azure infrastructure."
}

variable "location" {
  type        = string
  description = "The Azure region where all resources will be created (e.g. eastus, westus2)."
}

variable "environment" {
  type        = string
  description = "The environment name (e.g. dev, staging, prod). Used for tagging and naming conventions."
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to assign to all resources."
  default     = {}
}

# Networking
variable "vnet_address_space" {
  type        = list(string)
  description = "The address space for the Virtual Network (e.g. [\"10.0.0.0/16\"])."
  default     = ["10.0.0.0/16"]
}

variable "subnets" {
  type = map(object({
    address_prefixes  = list(string)
    service_endpoints = optional(list(string), [])
  }))
  description = "A map of subnets to create within the Virtual Network. Key is the subnet name."
  default = {
    default = {
      address_prefixes  = ["10.0.1.0/24"]
      service_endpoints = []
    }
  }
}

# Log Analytics
variable "log_analytics_sku" {
  type        = string
  description = "The SKU for the Log Analytics Workspace."
  default     = "PerGB2018"
}

variable "log_analytics_retention_days" {
  type        = number
  description = "The number of days to retain logs in the Log Analytics Workspace."
  default     = 30
}

# Key Vault
variable "key_vault_sku" {
  type        = string
  description = "The SKU for the Key Vault (standard or premium)."
  default     = "standard"
  validation {
    condition     = contains(["standard", "premium"], var.key_vault_sku)
    error_message = "key_vault_sku must be either 'standard' or 'premium'."
  }
}

variable "key_vault_soft_delete_retention_days" {
  type        = number
  description = "The number of days that Key Vault items are retained after soft delete."
  default     = 7
}

# Storage Account
variable "storage_account_tier" {
  type        = string
  description = "The performance tier for the diagnostics Storage Account (Standard or Premium)."
  default     = "Standard"
  validation {
    condition     = contains(["Standard", "Premium"], var.storage_account_tier)
    error_message = "storage_account_tier must be either 'Standard' or 'Premium'."
  }
}

variable "storage_account_replication_type" {
  type        = string
  description = "The replication type for the diagnostics Storage Account (LRS, GRS, RAGRS, ZRS)."
  default     = "LRS"
  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS"], var.storage_account_replication_type)
    error_message = "storage_account_replication_type must be one of: LRS, GRS, RAGRS, ZRS."
  }
}

# Managed Identity
variable "identity_role_assignments" {
  type = map(object({
    scope                = string
    role_definition_name = string
  }))
  description = "Additional role assignments to grant to the Managed Identity, beyond the defaults. The map key is a unique descriptive label for the assignment. Each entry requires a scope (resource ID) and a role_definition_name (Azure built-in role name). By default the identity is granted 'Key Vault Secrets User' on the landing zone Key Vault and 'Storage Blob Data Reader' on the landing zone Storage Account."
  default     = {}
}
