# Basic Example — Azure Infrastructure
#
# This example demonstrates a minimal but complete deployment of the azure-infra
# module. It provisions a resource group and a full landing zone including a
# Virtual Network, Log Analytics Workspace, Key Vault, and diagnostics Storage
# Account — plus a User-Assigned Managed Identity pre-wired with access to both.
#
# The identity_role_assignments input demonstrates how callers can extend the
# identity's access beyond the two default roles (Key Vault Secrets User and
# Storage Blob Data Reader) without modifying any child module.
#
# The subscription ID and resource group name are derived automatically from the
# authenticated provider via data.azurerm_client_config.current and the module's
# own output — no manual editing or variable files required.
#
# To run this example:
#   terraform init
#   terraform plan
#   terraform apply

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Reads the subscription ID and tenant ID from the authenticated provider
# session. Works with any auth method: az login, service principal,
# managed identity, environment variables, etc.
data "azurerm_client_config" "current" {}

module "azure_infra" {
  source = "../.."

  name        = "itential"
  location    = "eastus"
  environment = "dev"

  tags = {
    Project     = "itential"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }

  # Networking
  vnet_address_space = ["10.0.0.0/16"]

  subnets = {
    app = {
      address_prefixes  = ["10.0.1.0/24"]
      service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
    }
    data = {
      address_prefixes  = ["10.0.2.0/24"]
      service_endpoints = ["Microsoft.Storage"]
    }
  }

  # Log Analytics
  log_analytics_sku            = "PerGB2018"
  log_analytics_retention_days = 30

  # Key Vault
  key_vault_sku                        = "standard"
  key_vault_soft_delete_retention_days = 7

  # Storage Account
  storage_account_tier             = "Standard"
  storage_account_replication_type = "LRS"

  # Managed Identity — additional role assignments beyond the two defaults.
  # The identity already receives:
  #   - "Key Vault Secrets User"    on the landing zone Key Vault
  #   - "Storage Blob Data Reader"  on the landing zone Storage Account
  #
  # The entry below grants Log Analytics Contributor scoped to the resource
  # group this module creates. Both the subscription ID and resource group
  # name are resolved automatically — no hardcoded values or placeholder
  # substitution required.
  identity_role_assignments = {
    log_analytics_contributor = {
      scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${module.azure_infra.resource_group_name}"
      role_definition_name = "Log Analytics Contributor"
    }
  }
}

# ---------------------------------------------------------------------------
# Outputs — expose key values for inspection after apply
# ---------------------------------------------------------------------------

output "resource_group_name" {
  description = "The name of the provisioned Resource Group."
  value       = module.azure_infra.resource_group_name
}

output "vnet_id" {
  description = "The ID of the provisioned Virtual Network."
  value       = module.azure_infra.vnet_id
}

output "subnet_ids" {
  description = "A map of subnet names to their IDs."
  value       = module.azure_infra.subnet_ids
}

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace."
  value       = module.azure_infra.log_analytics_workspace_id
}

output "key_vault_uri" {
  description = "The URI of the Key Vault."
  value       = module.azure_infra.key_vault_uri
}

output "storage_account_name" {
  description = "The name of the diagnostics Storage Account."
  value       = module.azure_infra.storage_account_name
}

output "managed_identity_client_id" {
  description = "The client ID of the Managed Identity — use this in application configurations."
  value       = module.azure_infra.managed_identity_client_id
}

output "managed_identity_principal_id" {
  description = "The principal ID of the Managed Identity — use this to grant additional RBAC access."
  value       = module.azure_infra.managed_identity_principal_id
}
