# landing-zone

This module provisions the core Azure landing zone resources for a single environment. It is a child module intended to be called from a root module and should not be used in isolation.

## Resources Created

- **Virtual Network** — A VNet with configurable address space.
- **Subnets** — One or more subnets within the VNet, each with optional service endpoints.
- **Network Security Groups** — One NSG per subnet, associated automatically.
- **Log Analytics Workspace** — Centralized log collection and monitoring.
- **Key Vault** — Secrets management with network ACLs, purge protection, and audit logging enforced.
- **Diagnostics Storage Account** — Long-term diagnostic log storage with TLS 1.2 and blob soft-delete enforced.
- **Diagnostic Settings** — Wired for both the VNet and Key Vault to ship metrics/logs to the workspace and storage account.

## Usage

```hcl
module "landing_zone" {
  source = "./modules/landing-zone"

  name                = "myapp"
  location            = "eastus"
  environment         = "prod"
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Project     = "my-project"
    Environment = "prod"
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
      service_endpoints = []
    }
  }

  log_analytics_retention_days         = 90
  key_vault_sku                        = "standard"
  key_vault_soft_delete_retention_days = 30
  storage_account_replication_type     = "GRS"
}
```

## Requirements

| Name      | Version   |
|-----------|-----------|
| terraform | >= 1.9.0  |
| azurerm   | >= 4.0    |

## Inputs

| Name                                  | Description                                                         | Type                    | Default                              | Required |
|---------------------------------------|---------------------------------------------------------------------|-------------------------|--------------------------------------|:--------:|
| `name`                                | Base name prefix for all resources (3–20 alphanumeric/hyphen chars) | `string`                | n/a                                  | yes      |
| `location`                            | Azure region where resources will be created                        | `string`                | n/a                                  | yes      |
| `environment`                         | Environment label used in naming and tagging (1–10 chars)           | `string`                | n/a                                  | yes      |
| `resource_group_name`                 | Name of the pre-existing Resource Group                             | `string`                | n/a                                  | yes      |
| `tags`                                | Tags to apply to all resources                                      | `map(string)`           | `{}`                                 | no       |
| `vnet_address_space`                  | CIDR block(s) for the Virtual Network                               | `list(string)`          | `["10.0.0.0/16"]`                    | no       |
| `subnets`                             | Map of subnet definitions (name → address_prefixes, service_endpoints) | `map(object(...))`  | `{ default = { ... } }`             | no       |
| `log_analytics_sku`                   | SKU for the Log Analytics Workspace                                 | `string`                | `"PerGB2018"`                        | no       |
| `log_analytics_retention_days`        | Log retention period in days (30–730)                               | `number`                | `30`                                 | no       |
| `key_vault_sku`                       | Key Vault SKU (`standard` or `premium`)                             | `string`                | `"standard"`                         | no       |
| `key_vault_soft_delete_retention_days`| Soft-delete retention for Key Vault items (7–90 days)               | `number`                | `7`                                  | no       |
| `storage_account_tier`                | Storage account performance tier (`Standard` or `Premium`)          | `string`                | `"Standard"`                         | no       |
| `storage_account_replication_type`    | Storage replication type (`LRS`, `GRS`, `RAGRS`, or `ZRS`)         | `string`                | `"LRS"`                              | no       |

## Outputs

| Name                                    | Description                                            |
|-----------------------------------------|--------------------------------------------------------|
| `vnet_id`                               | ID of the Virtual Network                              |
| `vnet_name`                             | Name of the Virtual Network                            |
| `subnet_ids`                            | Map of subnet names to their IDs                       |
| `nsg_ids`                               | Map of NSG names to their IDs                          |
| `log_analytics_workspace_id`            | ID of the Log Analytics Workspace                      |
| `log_analytics_workspace_name`          | Name of the Log Analytics Workspace                    |
| `key_vault_id`                          | ID of the Key Vault                                    |
| `key_vault_name`                        | Name of the Key Vault                                  |
| `key_vault_uri`                         | URI of the Key Vault                                   |
| `storage_account_id`                    | ID of the diagnostics Storage Account                  |
| `storage_account_name`                  | Name of the diagnostics Storage Account                |
| `storage_account_primary_blob_endpoint` | Primary blob endpoint of the diagnostics Storage Account |

## Assumptions and Guarantees

This module enforces the following security guarantees via `postcondition` blocks:

- **Key Vault purge protection** is always enabled — secrets cannot be permanently deleted accidentally.
- **Storage account TLS 1.2** is always enforced — data in transit is encrypted with a modern protocol.

The following are assumed to be true before calling this module:

- The `resource_group_name` passed in refers to an already-existing Resource Group.
- The calling (root) module has configured the `azurerm` provider with appropriate credentials.
- The `name` and `environment` combination produces globally unique names for resources with uniqueness requirements (e.g., Key Vault, Storage Account).