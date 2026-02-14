# Data source para obtener el APIM existente
data "azurerm_api_management" "apim" {
  name                = var.apim_name
  resource_group_name = var.resource_group_name
}

# ==============================================================================
# API Management APIs - Importación desde OpenAPI
# ==============================================================================

resource "azurerm_api_management_api" "backend_api" {
  for_each = var.backend_apis

  name                  = each.value.name
  resource_group_name   = var.resource_group_name
  api_management_name   = data.azurerm_api_management.apim.name
  revision              = "1"
  display_name          = each.value.display_name
  path                  = each.value.path
  protocols             = each.value.protocols
  subscription_required = each.value.subscription_required

  subscription_key_parameter_names {
    header = each.value.subscription_key_header
    query  = each.value.subscription_key_query
  }

  # Importar desde OpenAPI — contenido pasado desde el caller con file()
  import {
    content_format = each.value.openapi_format
    content_value  = each.value.openapi_content
  }
}

# ==============================================================================
# API Management Policies - Cargar políticas XML estáticas
# ==============================================================================

resource "azurerm_api_management_api_policy" "policy" {
  for_each = var.backend_apis

  api_name            = azurerm_api_management_api.backend_api[each.key].name
  api_management_name = data.azurerm_api_management.apim.name
  resource_group_name = var.resource_group_name

  # Renderizar la política XML inyectando la URL del backend automáticamente
  xml_content = templatefile(
    "${path.module}/policies/${each.key}.xml",
    {
      backend_url = coalesce(each.value.backend_url, var.default_backend_url)
    }
  )
}

# ==============================================================================
# MCP Server — Exposición de la API como servidor MCP via azapi
# ==============================================================================

resource "azapi_resource" "mcp_server" {
  count = var.mcp_enabled ? 1 : 0

  type      = "Microsoft.ApiManagement/service/apis@${var.mcp_api_version}"
  name      = var.mcp_server_name
  parent_id = data.azurerm_api_management.apim.id

  schema_validation_enabled = false

  body = {
    properties = {
      type                = "mcp"
      displayName         = var.mcp_display_name
      description         = var.mcp_description
      path                = var.mcp_path
      protocols           = ["https"]
      subscriptionRequired = false

      mcpTools = [
        for key, tool in var.mcp_tools : {
          name        = key
          operationId = "${data.azurerm_api_management.apim.id}/apis/${var.backend_apis[tool.api_key].name}/operations/${tool.operation_id}"
          description = tool.description
        }
      ]
    }
  }

  depends_on = [
    azurerm_api_management_api.backend_api,
    azurerm_api_management_api_policy.policy,
  ]
}
