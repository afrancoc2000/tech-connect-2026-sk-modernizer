# ==============================================================================
# Azure API Management - APIs Deployment Module Outputs
# ==============================================================================

output "api_ids" {
  description = "Map of API names to their resource IDs"
  value = {
    for key, api in azurerm_api_management_api.backend_api :
    key => api.id
  }
}

output "api_urls" {
  description = "Map of API names to their gateway URLs"
  value = {
    for key, api in azurerm_api_management_api.backend_api :
    key => "${data.azurerm_api_management.apim.gateway_url}/${api.path}"
  }
}

output "deployment_summary" {
  description = "Summary of deployed APIs with JWT validation"
  value = {
    apim_name          = data.azurerm_api_management.apim.name
    gateway_url        = data.azurerm_api_management.apim.gateway_url
    tenant_id          = var.tenant_id
    apis_deployed      = length(azurerm_api_management_api.backend_api)
    apis_with_jwt      = length([for k, v in var.backend_apis : k if v.jwt_enabled])
    subscription_based = length([for k, v in var.backend_apis : k if v.subscription_required])
    api_paths = {
      for key, api in azurerm_api_management_api.backend_api :
      key => api.path
    }
  }
}

# ==============================================================================
# MCP Server Outputs
# ==============================================================================

output "mcp_enabled" {
  description = "Whether the MCP server was deployed"
  value       = var.mcp_enabled
}

output "mcp_server_id" {
  description = "Resource ID of the MCP server API"
  value       = var.mcp_enabled ? azapi_resource.mcp_server[0].id : null
}

output "mcp_endpoint_url" {
  description = "Full MCP endpoint URL (Streamable HTTP transport)"
  value       = var.mcp_enabled ? "${data.azurerm_api_management.apim.gateway_url}/${var.mcp_path}/mcp" : null
}

output "mcp_tools" {
  description = "Map of MCP tool names to their operation IDs"
  value = var.mcp_enabled ? {
    for key, tool in var.mcp_tools :
    key => "${data.azurerm_api_management.apim.id}/apis/${var.backend_apis[tool.api_key].name}/operations/${tool.operation_id}"
  } : {}
}
