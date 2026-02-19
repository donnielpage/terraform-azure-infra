output "id" {
  description = "The resource ID of the User-Assigned Managed Identity."
  value       = azurerm_user_assigned_identity.this.id
}

output "name" {
  description = "The name of the User-Assigned Managed Identity."
  value       = azurerm_user_assigned_identity.this.name
}

output "principal_id" {
  description = "The service principal ID of the Managed Identity. Use this when granting RBAC access to Azure resources."
  value       = azurerm_user_assigned_identity.this.principal_id
}

output "client_id" {
  description = "The client (application) ID of the Managed Identity. Use this in application and SDK configurations for authentication."
  value       = azurerm_user_assigned_identity.this.client_id
}

output "tenant_id" {
  description = "The tenant ID associated with the Managed Identity."
  value       = azurerm_user_assigned_identity.this.tenant_id
}
