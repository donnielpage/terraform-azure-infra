variable "name" {
  type        = string
  description = "The base name used to prefix all resources in the landing zone."

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{1,18}[a-zA-Z0-9]$", var.name))
    error_message = "name must be 3-20 characters, start and end with an alphanumeric character, and contain only letters, numbers, and hyphens."
  }
}

variable "location" {
  type        = string
  description = "The Azure region where all landing zone resources will be created (e.g. eastus, westus2)."
}

variable "environment" {
  type        = string
  description = "The environment name (e.g. dev, staging, prod). Used for tagging and naming conventions."

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,10}$", var.environment))
    error_message = "environment must be 1-10 characters and contain only letters, numbers, and hyphens."
  }
}

variable "resource_group_name" {
  type        = string
  description = "The name of the Resource Group in which all landing zone resources will be created."
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to assign to all resources in the landing zone."
  default     = {}
}

# Networking
variable "vnet_address_space" {
  type        = list(string)
  description = "The address space for the Virtual Network (e.g. [\"10.0.0.0/16\"])."
  default     = ["10.0.0.0/16"]

  validation {
    condition     = length(var.vnet_address_space) > 0
    error_message = "vnet_address_space must contain at least one CIDR block."
  }
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

  validation {
    condition     = length(var.subnets) > 0
    error_message = "subnets must contain at least one subnet definition."
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

  validation {
    condition     = var.log_analytics_retention_days >= 30 && var.log_analytics_retention_days <= 730
    error_message = "log_analytics_retention_days must be between 30 and 730."
  }
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

  validation {
    condition     = var.key_vault_soft_delete_retention_days >= 7 && var.key_vault_soft_delete_retention_days <= 90
    error_message = "key_vault_soft_delete_retention_days must be between 7 and 90."
  }
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
