output "resource_group_id" {
  description = "The ID of the Azure Resource Group."
  value       = azurerm_resource_group.main.id
}

output "resource_group_name" {
  description = "The name of the Azure Resource Group."
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "The Azure region where the Resource Group was created."
  value       = azurerm_resource_group.main.location
}

output "vnet_id" {
  description = "The ID of the landing zone Virtual Network."
  value       = module.landing_zone.vnet_id
}

output "vnet_name" {
  description = "The name of the landing zone Virtual Network."
  value       = module.landing_zone.vnet_name
}

output "subnet_ids" {
  description = "A map of subnet names to their IDs."
  value       = module.landing_zone.subnet_ids
}

output "nsg_ids" {
  description = "A map of Network Security Group names to their IDs."
  value       = module.landing_zone.nsg_ids
}

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace."
  value       = module.landing_zone.log_analytics_workspace_id
}

output "log_analytics_workspace_name" {
  description = "The name of the Log Analytics Workspace."
  value       = module.landing_zone.log_analytics_workspace_name
}

output "key_vault_id" {
  description = "The ID of the Key Vault."
  value       = module.landing_zone.key_vault_id
}

output "key_vault_name" {
  description = "The name of the Key Vault."
  value       = module.landing_zone.key_vault_name
}

output "key_vault_uri" {
  description = "The URI of the Key Vault."
  value       = module.landing_zone.key_vault_uri
}

output "storage_account_id" {
  description = "The ID of the diagnostics Storage Account."
  value       = module.landing_zone.storage_account_id
}

output "storage_account_name" {
  description = "The name of the diagnostics Storage Account."
  value       = module.landing_zone.storage_account_name
}

output "storage_account_primary_blob_endpoint" {
  description = "The primary blob endpoint of the diagnostics Storage Account."
  value       = module.landing_zone.storage_account_primary_blob_endpoint
}

output "managed_identity_id" {
  description = "The resource ID of the User-Assigned Managed Identity."
  value       = module.managed_identity.id
}

output "managed_identity_name" {
  description = "The name of the User-Assigned Managed Identity."
  value       = module.managed_identity.name
}

output "managed_identity_principal_id" {
  description = "The service principal ID of the Managed Identity. Use this when granting additional RBAC access to Azure resources."
  value       = module.managed_identity.principal_id
}

output "managed_identity_client_id" {
  description = "The client (application) ID of the Managed Identity. Use this in application and SDK configurations for authentication."
  value       = module.managed_identity.client_id
}

output "managed_identity_tenant_id" {
  description = "The tenant ID associated with the Managed Identity."
  value       = module.managed_identity.tenant_id
}
