# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.name}-${var.environment}-rg"
  location = var.location
  tags     = var.tags
}

# Landing Zone
module "landing_zone" {
  source = "./modules/landing-zone"

  name                = var.name
  location            = var.location
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  # Networking
  vnet_address_space = var.vnet_address_space
  subnets            = var.subnets

  # Log Analytics
  log_analytics_sku            = var.log_analytics_sku
  log_analytics_retention_days = var.log_analytics_retention_days

  # Key Vault
  key_vault_sku                        = var.key_vault_sku
  key_vault_soft_delete_retention_days = var.key_vault_soft_delete_retention_days

  # Storage Account
  storage_account_tier             = var.storage_account_tier
  storage_account_replication_type = var.storage_account_replication_type
}

# Managed Identity
#
# By default the identity is granted two roles scoped to the landing zone
# resources created above, following the dependency inversion pattern — the
# root module wires the modules together rather than having either child module
# reach into the other.  Callers can extend access via identity_role_assignments
# without touching either child module.
module "managed_identity" {
  source = "./modules/managed-identity"

  name                = "${var.name}-${var.environment}-id"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  role_assignments = merge(
    {
      key_vault_secrets_user = {
        scope                = module.landing_zone.key_vault_id
        role_definition_name = "Key Vault Secrets User"
      }
      storage_blob_data_reader = {
        scope                = module.landing_zone.storage_account_id
        role_definition_name = "Storage Blob Data Reader"
      }
    },
    var.identity_role_assignments
  )
}
