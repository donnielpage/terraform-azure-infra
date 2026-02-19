variable "name" {
  type        = string
  description = "The name of the User-Assigned Managed Identity. Must be 3–128 characters, start and end with an alphanumeric character, and contain only letters, numbers, hyphens, and underscores."

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9_-]{1,126}[a-zA-Z0-9]$", var.name))
    error_message = "name must be 3-128 characters, start and end with an alphanumeric character, and contain only letters, numbers, hyphens, and underscores."
  }
}

variable "location" {
  type        = string
  description = "The Azure region where the Managed Identity will be created (e.g. eastus, westus2)."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the Resource Group in which the Managed Identity will be created."
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to assign to the Managed Identity."
  default     = {}
}

# Role Assignments
variable "role_assignments" {
  type = map(object({
    scope                = string
    role_definition_name = string
  }))
  description = <<-EOT
    A map of role assignments to grant to the Managed Identity. The map key is a
    unique, descriptive label for the assignment (e.g. "key_vault_secrets_user").

    Each entry requires:
      - scope                : The resource ID to grant access on (resource, resource group, or subscription).
      - role_definition_name : The name of an Azure built-in role (e.g. "Key Vault Secrets User").

    Example:
      role_assignments = {
        key_vault_secrets_user = {
          scope                = "/subscriptions/.../resourceGroups/.../providers/Microsoft.KeyVault/vaults/my-kv"
          role_definition_name = "Key Vault Secrets User"
        }
        storage_blob_reader = {
          scope                = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Storage/storageAccounts/mysa"
          role_definition_name = "Storage Blob Data Reader"
        }
      }
  EOT
  default     = {}
}
