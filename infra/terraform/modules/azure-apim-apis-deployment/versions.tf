# ==============================================================================
# Azure API Management - APIs Deployment Module — Provider Requirements
# ==============================================================================
# azapi is required for MCP server creation (type: 'mcp' + mcpTools)
# since azurerm does not support preview API properties.

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
  }
}
