# managed-identity

This module creates a [User-Assigned Managed Identity](https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview) and an optional set of Azure RBAC role assignments scoped to any combination of resources, resource groups, or subscriptions.

It is a child module intended to be called from a root module. Provider configuration is inherited from the caller — no `provider` block is included here.

## Why User-Assigned vs System-Assigned?

User-assigned identities have a lifecycle independent of the resource they are attached to. This means:

- The identity (and its role assignments) can be created before the workload that uses it.
- The same identity can be shared across multiple resources.
- Deleting a workload does not automatically revoke credentials.

## Resources Created

| Resource | Description |
|----------|-------------|
| `azurerm_user_assigned_identity` | The managed identity itself. |
| `azurerm_role_assignment` (×N) | One role assignment per entry in `var.role_assignments`. |

## Usage

```hcl
module "managed_identity" {
  source = "./modules/managed-identity"

  name                = "myapp-prod-id"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Project     = "myapp"
    Environment = "prod"
    ManagedBy   = "Terraform"
  }

  role_assignments = {
    key_vault_secrets_user = {
      scope                = azurerm_key_vault.main.id
      role_definition_name = "Key Vault Secrets User"
    }
    storage_blob_data_reader = {
      scope                = azurerm_storage_account.diag.id
      role_definition_name = "Storage Blob Data Reader"
    }
  }
}
```

### Referencing the identity in other resources

After creation, attach the identity to a workload using the `id` output, and use `client_id` in any SDK or application configuration that needs to authenticate:

```hcl
resource "azurerm_linux_virtual_machine" "app" {
  # ...

  identity {
    type         = "UserAssigned"
    identity_ids = [module.managed_identity.id]
  }
}
```

```hcl
# Application environment variable for DefaultAzureCredential / SDK auth
AZURE_CLIENT_ID = module.managed_identity.client_id
```

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.9.0 |
| azurerm   | >= 4.0   |

## Providers

| Name    | Version |
|---------|---------|
| azurerm | >= 4.0  |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Name of the User-Assigned Managed Identity. Must be 3–128 characters, start and end with an alphanumeric character, and contain only letters, numbers, hyphens, and underscores. | `string` | n/a | yes |
| `location` | Azure region where the identity will be created (e.g. `eastus`, `westus2`). | `string` | n/a | yes |
| `resource_group_name` | Name of the pre-existing Resource Group to create the identity in. | `string` | n/a | yes |
| `tags` | Map of tags to assign to the identity. | `map(string)` | `{}` | no |
| `role_assignments` | Map of role assignments to grant to the identity. Key is a unique descriptive label. Each value requires `scope` (resource ID) and `role_definition_name` (Azure built-in role name). | `map(object({scope, role_definition_name}))` | `{}` | no |

### `role_assignments` map key guidance

Use a stable, descriptive key for each assignment. The key becomes part of the Terraform resource address (`azurerm_role_assignment.this["<key>"]`), so changing a key will destroy and recreate that assignment. Good examples:

```hcl
role_assignments = {
  key_vault_secrets_user   = { ... }   # good — stable, descriptive
  storage_blob_data_reader = { ... }   # good — stable, descriptive
  assignment_1             = { ... }   # avoid — not descriptive
}
```

### Common Azure built-in role names

| Role Name | Typical Use |
|-----------|-------------|
| `Key Vault Secrets User` | Read secret values from a Key Vault |
| `Key Vault Reader` | Read Key Vault metadata (not secret values) |
| `Storage Blob Data Reader` | Read blobs from a Storage Account |
| `Storage Blob Data Contributor` | Read, write, and delete blobs |
| `Monitoring Reader` | Read monitoring data and settings |
| `Reader` | Read-only access to all resources in scope |

For a full list see the [Azure built-in roles reference](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles).

## Outputs

| Name | Description |
|------|-------------|
| `id` | The resource ID of the User-Assigned Managed Identity. Use this to attach the identity to a workload (`identity_ids`). |
| `name` | The name of the User-Assigned Managed Identity. |
| `principal_id` | The service principal ID of the identity. Use this when creating additional RBAC role assignments outside this module. |
| `client_id` | The client (application) ID of the identity. Use this in application and SDK configurations for authentication (e.g. `AZURE_CLIENT_ID`). |
| `tenant_id` | The tenant ID associated with the identity. |

## Assumptions and Guarantees

**Assumptions** — the following must be true before calling this module:

- The `resource_group_name` passed in refers to an already-existing Resource Group in the same subscription.
- The caller's `azurerm` provider has sufficient permissions to create managed identities (`Microsoft.ManagedIdentity/userAssignedIdentities/write`) and role assignments (`Microsoft.Authorization/roleAssignments/write`) on all provided scopes.
- Every `role_definition_name` in `role_assignments` is a valid Azure built-in role name accessible in the target subscription.

**Guarantees** — the following are enforced by this module:

- After creation, the identity will always have a valid `principal_id` UUID, verified by a `postcondition` block. If Azure fails to assign a service principal, the apply will fail with a clear error message.
- Role assignments use the identity's `principal_id` directly, ensuring assignments are always tied to this specific identity.
- Map-keyed `for_each` is used for role assignments, so adding or removing individual assignments never affects unrelated assignments.