data "azurerm_client_config" "current" {}

# Virtual Network
resource "azurerm_virtual_network" "this" {
  name                = "${var.name}-${var.environment}-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

# Subnets
resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = each.value.service_endpoints
}

# Network Security Groups
resource "azurerm_network_security_group" "this" {
  for_each = var.subnets

  name                = "${var.name}-${var.environment}-${each.key}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# NSG Subnet Associations
resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = var.subnets

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "this" {
  name                = "${var.name}-${var.environment}-law"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_analytics_retention_days
  tags                = var.tags
}

# Key Vault
resource "azurerm_key_vault" "this" {
  name                       = "${var.name}-${var.environment}-kv"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = var.key_vault_sku
  soft_delete_retention_days = var.key_vault_soft_delete_retention_days
  purge_protection_enabled   = true
  tags                       = var.tags

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }

  lifecycle {
    postcondition {
      condition     = self.purge_protection_enabled
      error_message = "Key Vault purge protection must be enabled to prevent accidental permanent deletion of secrets."
    }
  }
}

# Diagnostics Storage Account
resource "azurerm_storage_account" "this" {
  name                     = replace("${var.name}${var.environment}diag", "-", "")
  location                 = var.location
  resource_group_name      = var.resource_group_name
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
  min_tls_version          = "TLS1_2"
  tags                     = var.tags

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }

  lifecycle {
    postcondition {
      condition     = self.min_tls_version == "TLS1_2"
      error_message = "Storage account must enforce a minimum TLS version of TLS1_2 for secure data transmission."
    }
  }
}

# Diagnostic Settings - Virtual Network
resource "azurerm_monitor_diagnostic_setting" "vnet" {
  name                       = "${azurerm_virtual_network.this.name}-diag"
  target_resource_id         = azurerm_virtual_network.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  storage_account_id         = azurerm_storage_account.this.id

  enabled_metric {
    category = "AllMetrics"
  }
}

# Diagnostic Settings - Key Vault
resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name                       = "${azurerm_key_vault.this.name}-diag"
  target_resource_id         = azurerm_key_vault.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  storage_account_id         = azurerm_storage_account.this.id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
