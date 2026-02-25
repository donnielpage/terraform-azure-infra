# Basic Example — Azure Infrastructure (Self-Contained)
#
# This is a self-contained configuration that provisions a resource group and a
# full landing zone including a Virtual Network, Log Analytics Workspace, Key
# Vault, and diagnostics Storage Account — plus a User-Assigned Managed Identity
# pre-wired with access to both.
#
# All resources are defined directly in this file. No external modules are
# referenced.
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

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret
}

locals {
  name        = "itential"
  location    = "eastus"
  environment = "dev"

  tags = {
    Project     = "itential"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }

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
}

# ---------------------------------------------------------------------------
# Provider data
# ---------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

# ---------------------------------------------------------------------------
# Resource Group
# ---------------------------------------------------------------------------

resource "azurerm_resource_group" "main" {
  name     = "${local.name}-${local.environment}-rg"
  location = local.location
  tags     = local.tags
}

# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------

resource "azurerm_virtual_network" "main" {
  name                = "${local.name}-${local.environment}-vnet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = local.vnet_address_space
  tags                = local.tags
}

resource "azurerm_subnet" "main" {
  for_each = local.subnets

  name                 = each.key
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = each.value.service_endpoints
}

resource "azurerm_network_security_group" "main" {
  for_each = local.subnets

  name                = "${local.name}-${local.environment}-${each.key}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_subnet_network_security_group_association" "main" {
  for_each = local.subnets

  subnet_id                 = azurerm_subnet.main[each.key].id
  network_security_group_id = azurerm_network_security_group.main[each.key].id
}

# ---------------------------------------------------------------------------
# Log Analytics Workspace
# ---------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${local.name}-${local.environment}-law"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

# ---------------------------------------------------------------------------
# Key Vault
# ---------------------------------------------------------------------------

resource "azurerm_key_vault" "main" {
  name                       = "${local.name}-${local.environment}-kv"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = true
  tags                       = local.tags

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
}

# ---------------------------------------------------------------------------
# Diagnostics Storage Account
# ---------------------------------------------------------------------------

resource "azurerm_storage_account" "main" {
  name                     = replace("${local.name}${local.environment}diag", "-", "")
  location                 = azurerm_resource_group.main.location
  resource_group_name      = azurerm_resource_group.main.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  tags                     = local.tags

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }
}

# ---------------------------------------------------------------------------
# Diagnostic Settings
# ---------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "vnet" {
  name                       = "${azurerm_virtual_network.main.name}-diag"
  target_resource_id         = azurerm_virtual_network.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  storage_account_id         = azurerm_storage_account.main.id

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name                       = "${azurerm_key_vault.main.name}-diag"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  storage_account_id         = azurerm_storage_account.main.id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

# ---------------------------------------------------------------------------
# Managed Identity
# ---------------------------------------------------------------------------

resource "azurerm_user_assigned_identity" "main" {
  name                = "${local.name}-${local.environment}-id"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_role_assignment" "main" {
  for_each = {
    key_vault_secrets_user = {
      scope                = azurerm_key_vault.main.id
      role_definition_name = "Key Vault Secrets User"
    }
    storage_blob_data_reader = {
      scope                = azurerm_storage_account.main.id
      role_definition_name = "Storage Blob Data Reader"
    }
    log_analytics_contributor = {
      scope                = azurerm_resource_group.main.id
      role_definition_name = "Log Analytics Contributor"
    }
  }

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = azurerm_user_assigned_identity.main.principal_id
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------

output "resource_group_name" {
  description = "The name of the provisioned Resource Group."
  value       = azurerm_resource_group.main.name
}

output "vnet_id" {
  description = "The ID of the provisioned Virtual Network."
  value       = azurerm_virtual_network.main.id
}

output "subnet_ids" {
  description = "A map of subnet names to their IDs."
  value       = { for k, v in azurerm_subnet.main : k => v.id }
}

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace."
  value       = azurerm_log_analytics_workspace.main.id
}

output "key_vault_uri" {
  description = "The URI of the Key Vault."
  value       = azurerm_key_vault.main.vault_uri
}

output "storage_account_name" {
  description = "The name of the diagnostics Storage Account."
  value       = azurerm_storage_account.main.name
}

output "managed_identity_client_id" {
  description = "The client ID of the Managed Identity — use this in application configurations."
  value       = azurerm_user_assigned_identity.main.client_id
}

output "managed_identity_principal_id" {
  description = "The principal ID of the Managed Identity — use this to grant additional RBAC access."
  value       = azurerm_user_assigned_identity.main.principal_id
}
