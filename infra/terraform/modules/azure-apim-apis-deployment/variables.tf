# ==============================================================================
# Azure API Management - APIs Deployment Module Variables
# ==============================================================================
# Variables para publicar APIs automáticamente con validación JWT de Entra ID

variable "resource_group_name" {
  type        = string
  description = "Nombre del Resource Group donde está desplegado APIM"
}

variable "apim_name" {
  type        = string
  description = "Nombre del servicio API Management existente"
}

variable "tenant_id" {
  type        = string
  description = "Tenant ID de Azure AD/Entra ID para validación JWT"
}

variable "default_backend_url" {
  type        = string
  description = "URL por defecto del backend (Container App). Se usa si la API no define su propio backend_url."
  default     = ""
}

variable "backend_apis" {
  type = map(object({
    name             = string
    display_name     = string
    path             = string
    protocols        = list(string)
    openapi_format   = string
    openapi_content  = string                # Contenido del spec OpenAPI (pasar con file() desde el caller)
    backend_url      = optional(string, "") # URL del backend; si vacío usa default_backend_url

    # JWT Configuration (for future use)
    jwt_enabled              = bool
    jwt_audience             = string
    jwt_issuer               = string
    jwt_required_claims      = map(string)

    # Rate limiting (for future use)
    rate_limit_calls         = number
    rate_limit_period        = number

    # Subscription (disabled - auth via JWT only)
    subscription_required    = bool
    subscription_key_header  = string
    subscription_key_query   = string
  }))
  description = "Configuración de APIs a publicar en APIM. Backend URL se inyecta automáticamente en la política XML."
  default     = {}
}

# ==============================================================================
# MCP Server Configuration
# ==============================================================================

variable "mcp_enabled" {
  type        = bool
  description = "Whether to create an MCP server that exposes selected API operations as MCP tools"
  default     = false
}

variable "mcp_server_name" {
  type        = string
  description = "Name identifier for the MCP server API resource in APIM"
  default     = "modernizer-mcp"
}

variable "mcp_display_name" {
  type        = string
  description = "Display name of the MCP server"
  default     = "Code Modernizer MCP"
}

variable "mcp_description" {
  type        = string
  description = "Description of the MCP server"
  default     = "MCP server exposing the Code Modernizer Agent API operations as tools"
}

variable "mcp_path" {
  type        = string
  description = "Base path for the MCP server endpoint (MCP endpoint will be at {gateway_url}/{mcp_path}/mcp)"
  default     = "modernizer-mcp"
}

variable "mcp_api_version" {
  type        = string
  description = "ARM API version for the MCP server resource (must support type='mcp' and mcpTools)"
  default     = "2025-03-01-preview"
}

variable "mcp_tools" {
  type = map(object({
    display_name = string
    description  = string
    api_key      = string # Key in var.backend_apis that owns the operation
    operation_id = string # OpenAPI operationId to expose as MCP tool
  }))
  description = "Map of MCP tools to create. Each tool maps an APIM API operation to an MCP tool."
  default     = {}
}
