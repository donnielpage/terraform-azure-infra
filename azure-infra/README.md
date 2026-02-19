# azure-infra

This module provisions a complete Azure infrastructure stack for a single environment, including:

- **Resource Group**: A dedicated resource group to contain all provisioned resources.
- **Landing Zone**: Core networking, observability, and security infrastructure:
  - Virtual Network with configurable subnets and Network Security Group associations
  - Log Analytics Workspace for centralized monitoring and diagnostics
  - Key Vault with network ACLs and purge protection enforced
  - Diagnostics Storage Account with TLS 1.2 enforcement and blob soft-delete
- **Managed Identity**: A User-Assigned Managed Identity pre-wired with access to the landing zone Key Vault and Storage Account. Additional role assignments can be supplied by the caller.

## Usage

```hcl
module "azure_infra" {
  source = "./azure-infra"

  name        = "myapp"
  location    = "eastus"
  environment = "prod"

  tags = {
    Project     = "my-project"
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}
```

See the [`examples/basic`](./examples/basic) directory for a complete working example.

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.9.0 |
| azurerm   | ~> 4.0   |

## Providers

| Name    | Version |
|---------|---------|
| azurerm | ~> 4.0  |

## Modules

| Name              | Source                      | Description                                                                 |
|-------------------|-----------------------------|-----------------------------------------------------------------------------|
| `landing_zone`    | `./modules/landing-zone`    | Core networking, observability, and security resources                      |
| `managed_identity`| `./modules/managed-identity`| User-Assigned Managed Identity pre-wired with access to landing zone resources |

## Inputs

### Required

| Name          | Description                                                                 | Type     |
|---------------|-----------------------------------------------------------------------------|----------|
| `name`        | Base name prefix for all resources. Must be 3–20 alphanumeric/hyphen chars. | `string` |
| `location`    | Azure region where all resources will be created (e.g. `eastus`, `westus2`).| `string` |
| `environment` | Environment name used for naming and tagging (e.g. `dev`, `staging`, `prod`).| `string`|

### Optional

| Name                                    | Description                                                                                      | Type                              | Default                         |
|-----------------------------------------|--------------------------------------------------------------------------------------------------|-----------------------------------|---------------------------------|
| `tags`                                  | Map of tags to assign to all resources.                                                          | `map(string)`                     | `{}`                            |
| `vnet_address_space`                    | Address space CIDR block(s) for the Virtual Network.                                             | `list(string)`                    | `["10.0.0.0/16"]`               |
| `subnets`                               | Map of subnet definitions. Key is the subnet name.                                               | `map(object({...}))`              | see `variables.tf`              |
| `log_analytics_sku`                     | SKU for the Log Analytics Workspace.                                                             | `string`                          | `"PerGB2018"`                   |
| `log_analytics_retention_days`          | Number of days to retain logs (30–730).                                                          | `number`                          | `30`                            |
| `key_vault_sku`                         | SKU for the Key Vault (`standard` or `premium`).                                                 | `string`                          | `"standard"`                    |
| `key_vault_soft_delete_retention_days`  | Days Key Vault items are retained after soft delete (7–90).                                      | `number`                          | `7`                             |
| `storage_account_tier`                  | Performance tier for the diagnostics Storage Account (`Standard` or `Premium`).                  | `string`                          | `"Standard"`                    |
| `storage_account_replication_type`      | Replication type for the diagnostics Storage Account (`LRS`, `GRS`, `RAGRS`, `ZRS`).            | `string`                          | `"LRS"`                         |
| `identity_role_assignments`             | Additional role assignments to grant to the Managed Identity beyond the defaults. See note below.| `map(object({scope, role_definition_name}))` | `{}`           |

> **`identity_role_assignments` note:** By default the Managed Identity is granted
> `Key Vault Secrets User` on the landing zone Key Vault and `Storage Blob Data Reader`
> on the landing zone Storage Account. Use this variable to grant access to any
> additional resources without modifying the module.
>
> ```hcl
> identity_role_assignments = {
>   log_analytics_contributor = {
>     scope                = "/subscriptions/<id>/resourceGroups/<rg>"
>     role_definition_name = "Log Analytics Contributor"
>   }
> }
> ```

## Outputs

### Resource Group

| Name                      | Description                                        |
|---------------------------|----------------------------------------------------|
| `resource_group_id`       | The ID of the Azure Resource Group.                |
| `resource_group_name`     | The name of the Azure Resource Group.              |
| `resource_group_location` | The Azure region where the Resource Group was created. |

### Networking

| Name         | Description                                  |
|--------------|----------------------------------------------|
| `vnet_id`    | The ID of the landing zone Virtual Network.  |
| `vnet_name`  | The name of the landing zone Virtual Network.|
| `subnet_ids` | A map of subnet names to their IDs.          |
| `nsg_ids`    | A map of NSG names to their IDs.             |

### Observability

| Name                          | Description                              |
|-------------------------------|------------------------------------------|
| `log_analytics_workspace_id`  | The ID of the Log Analytics Workspace.   |
| `log_analytics_workspace_name`| The name of the Log Analytics Workspace. |

### Security

| Name                                    | Description                                              |
|-----------------------------------------|----------------------------------------------------------|
| `key_vault_id`                          | The ID of the Key Vault.                                 |
| `key_vault_name`                        | The name of the Key Vault.                               |
| `key_vault_uri`                         | The URI of the Key Vault.                                |
| `storage_account_id`                    | The ID of the diagnostics Storage Account.               |
| `storage_account_name`                  | The name of the diagnostics Storage Account.             |
| `storage_account_primary_blob_endpoint` | The primary blob endpoint of the diagnostics Storage Account. |

### Managed Identity

| Name                           | Description                                                                                   |
|--------------------------------|-----------------------------------------------------------------------------------------------|
| `managed_identity_id`          | The resource ID of the User-Assigned Managed Identity.                                        |
| `managed_identity_name`        | The name of the User-Assigned Managed Identity.                                               |
| `managed_identity_principal_id`| The service principal ID. Use this when granting additional RBAC access to Azure resources.   |
| `managed_identity_client_id`   | The client (application) ID. Use this in application and SDK configurations for authentication.|
| `managed_identity_tenant_id`   | The tenant ID associated with the Managed Identity.                                           |