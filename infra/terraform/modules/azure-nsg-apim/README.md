# Azure NSG for API Management Module

This module creates a Network Security Group (NSG) with all required rules for Azure API Management VNet integration in External mode.

## Features

✅ **Complete NSG Rules** based on [official Microsoft documentation](https://learn.microsoft.com/en-us/azure/api-management/api-management-using-with-vnet)

### Inbound Rules
- Client communication (ports 80, 443 from Internet)
- Management endpoint (port 3443 from ApiManagement service tag)
- Azure Load Balancer (port 6390)
- Azure Traffic Manager (port 443)

### Outbound Rules
- Certificate validation (port 80 to Internet)
- Azure Storage dependency (port 443)
- Azure SQL dependency (port 1433)
- Azure Key Vault dependency (port 443)
- Azure Monitor/Application Insights (ports 1886, 443)

## Usage

```hcl
module "nsg_apim" {
  source = "./modules/azure-nsg-apim"
  
  name                = "nsg-apim-example"
  location            = "westus"
  resource_group_name = "rg-example"
  subnet_id           = azurerm_subnet.apim.id
  
  tags = {
    environment = "production"
    component   = "api-management"
  }
}
```

## Requirements

- Terraform >= 1.0
- AzureRM Provider >= 3.0

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| name | Name of the NSG | string | yes |
| location | Azure region | string | yes |
| resource_group_name | Resource group name | string | yes |
| subnet_id | Subnet ID to associate | string | yes |
| tags | Tags for the NSG | map(string) | no |

## Outputs

| Name | Description |
|------|-------------|
| id | NSG resource ID |
| name | NSG name |
| location | NSG location |

## References

- [API Management VNet Integration](https://learn.microsoft.com/en-us/azure/api-management/api-management-using-with-vnet)
- [Virtual Network Configuration Reference](https://learn.microsoft.com/en-us/azure/api-management/virtual-network-reference)
