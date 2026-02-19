# terraform-azure-infra

A collection of Terraform modules for provisioning Azure infrastructure. This repository is intended as a reusable base that teams can clone, extend, and build upon to deploy consistent, secure, and well-documented Azure environments.

## Repository Structure

```
terraform-azure-infra/
└── azure-infra/               # Root module — provisions a complete Azure environment
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── versions.tf
    ├── README.md
    ├── LICENSE
    ├── modules/
    │   ├── landing-zone/      # Core networking, observability, and security resources
    │   └── managed-identity/  # User-Assigned Managed Identity with RBAC role assignments
    └── examples/
        └── basic/             # Complete working example of the root module
```

## Modules

### [`azure-infra`](./azure-infra)
The root module and primary entrypoint for this repository. It orchestrates the child modules below to provision a complete Azure environment including a Resource Group, networking, observability, security, and a managed identity — all wired together using module composition.

### [`modules/landing-zone`](./azure-infra/modules/landing-zone)
Provisions the core Azure landing zone resources for a single environment:
- Virtual Network with configurable subnets and Network Security Groups
- Log Analytics Workspace for centralized monitoring
- Key Vault with network ACLs and purge protection enforced
- Diagnostics Storage Account with TLS 1.2 and blob soft-delete enforced
- Diagnostic settings wired to both the VNet and Key Vault

### [`modules/managed-identity`](./azure-infra/modules/managed-identity)
Creates a User-Assigned Managed Identity and an optional set of Azure RBAC role assignments. The identity is pre-wired by the root module with read access to the landing zone Key Vault and Storage Account, and can be extended with additional role assignments without modifying any child module.

## Getting Started

### Prerequisites
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.9.0
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) >= 2.x
- An active Azure subscription

### Quickstart

1. **Clone the repository**
   ```bash
   git clone https://github.com/donnielpage/terraform-azure-infra.git
   cd terraform-azure-infra
   ```

2. **Authenticate to Azure**
   ```bash
   az login
   az account set --subscription "<your_subscription_name_or_id>"
   ```

3. **Run the basic example**
   ```bash
   cd azure-infra/examples/basic
   terraform init
   terraform plan
   terraform apply
   ```

See the [`examples/basic`](./azure-infra/examples/basic) directory for a complete working configuration.

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.9.0 |
| azurerm   | ~> 4.0   |

## Contributing

Contributions are welcome. Please open an issue or pull request for any bugs, improvements, or new module suggestions.

## License

[MIT](./azure-infra/LICENSE)