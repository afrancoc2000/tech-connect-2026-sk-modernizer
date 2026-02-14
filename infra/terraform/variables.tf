variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
}

variable "create_resource_group" {
  description = "Whether to create a new resource group or use an existing one"
  type        = bool
  default     = true
}

variable "environment_name" {
  description = "Name of the environment (dev, stg, prd) — used for resource naming and tagging"
  type        = string

  validation {
    condition     = length(var.environment_name) >= 1 && length(var.environment_name) <= 64
    error_message = "Environment name must be between 1 and 64 characters"
  }
}

variable "location" {
  description = "Azure region. See https://learn.microsoft.com/en-us/azure/ai-foundry/agents/concepts/hosted-agents for supported regions"
  type        = string
}

# --- Virtual Network ---

variable "virtual_network_exists" {
  description = "Whether to use an existing virtual network instead of creating a new one"
  type        = bool
  default     = false
}

variable "azure_bastion_exists" {
  description = "Whether an Azure Bastion already exists (skip its subnet creation)"
  type        = bool
  default     = false
}

variable "virtual_network_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "virtual_network_address_space" {
  description = "Address space for the virtual network in CIDR notation"
  type        = list(string)
}

variable "virtual_network_subnets" {
  description = "List of subnet definitions for the virtual network"
  type = list(object({
    name              = string
    address_prefix    = string
    service_endpoints = list(string)
    delegation = optional(list(object({
      name                    = string
      service_delegation_name = string
      actions                 = list(string)
    })), [])
  }))
}

# --- Container Registry ---

variable "acr_sku" {
  description = "SKU tier for the Container Registry (Basic, Standard, Premium)"
  type        = string
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "SKU must be Basic, Standard, or Premium"
  }
}

variable "acr_zone_redundancy_enabled" {
  description = "Whether zone redundancy is enabled for ACR. Requires Premium SKU"
  type        = bool
  default     = false
}

# --- Model deployment ---

variable "model_name" {
  description = "Name of the AI model to deploy"
  type        = string
  default     = "gpt-4.1"
}

variable "model_format" {
  description = "Format of the AI model"
  type        = string
  default     = "OpenAI"
}

variable "model_version" {
  description = "Version of the AI model"
  type        = string
  default     = "2025-04-14"
}

variable "model_sku_name" {
  description = "SKU name for the model deployment"
  type        = string
  default     = "GlobalStandard"
}

variable "model_capacity" {
  description = "Capacity (TPM) for the model deployment"
  type        = number
  default     = 10
}

# --- AI Foundry ---

variable "project_name" {
  description = "Name of the AI Foundry Project"
  type        = string
  default     = "agent-flow"
}

variable "capability_host_name" {
  description = "Name of the Agents Capability Host"
  type        = string
  default     = "agents"
}

variable "appi_connection_name" {
  description = "Name of the Application Insights connection in AI Foundry"
  type        = string
  default     = "appi-connection"
}

# --- Hosted agent container ---

variable "agent_name" {
  description = "Name of the hosted agent registered in Foundry"
  type        = string
  default     = "agent-flow-hosted"
}

variable "agent_cpu" {
  description = "CPU allocation for the hosted agent container (e.g. 1, 2, 3.5)"
  type        = string
  default     = "1"
}

variable "agent_memory" {
  description = "Memory allocation for the hosted agent container (e.g. 2Gi, 4Gi, 7Gi)"
  type        = string
  default     = "2Gi"
}

# --- Misc ---

variable "enable_telemetry" {
  description = "Enable telemetry collection for Azure Verified Modules"
  type        = bool
  default     = true
}

variable "timestamp" {
  description = "Fixed timestamp for resource token generation. Leave empty to auto-generate"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}


# ============================================================================
# CONTAINER APPS ENVIRONMENT VARIABLES
# ============================================================================

variable "container_apps_environment_name" {
  description = "The name of the Container Apps Environment"
  type        = string
}

variable "container_apps_environment_infrastructure_subnet_name" {
  description = "The name of the subnet for Container Apps Environment infrastructure components"
  type        = string
}

variable "container_apps_environment_internal_load_balancer_enabled" {
  description = "Should the Container Apps Environment use an internal load balancer"
  type        = bool
  default     = false
}

variable "container_apps_environment_zone_redundancy_enabled" {
  description = "Should the Container Apps Environment be zone redundant"
  type        = bool
  default     = false
}



variable "container_apps_environment_mutual_tls_enabled" {
  description = "Should mutual transport layer security (mTLS) be enabled"
  type        = bool
  default     = false
}

variable "container_apps_environment_public_network_access" {
  description = "Property to allow or block all public traffic. Allowed values: 'Enabled', 'Disabled'"
  type        = string
  default     = "Disabled"
  validation {
    condition     = contains(["Enabled", "Disabled"], var.container_apps_environment_public_network_access)
    error_message = "public_network_access must be either 'Enabled' or 'Disabled'."
  }
}

variable "container_apps_environment_peer_traffic_encryption_enabled" {
  description = "Boolean indicating whether the peer traffic encryption is enabled"
  type        = bool
  default     = false
}

variable "container_apps_environment_dapr_application_insights_connection_string" {
  description = "Application Insights connection string used by Dapr"
  type        = string
  default     = null
  sensitive   = true
}

variable "container_apps_environment_dapr_application_insights_instrumentation_key" {
  description = "Azure Monitor instrumentation key used by Dapr to export Service to Service communication telemetry"
  type        = string
  default     = null
  sensitive   = true
}

variable "container_apps_environment_workload_profile" {
  description = "Workload profile configuration for the Container Apps Environment"
  type = list(object({
    name                = string
    workloadProfileType = string
    minimumCount        = optional(number)
    maximumCount        = optional(number)
  }))
  default = [
    {
      name                = "Consumption"
      workloadProfileType = "Consumption"
    }
  ]
}

variable "container_apps_environment_tags" {
  description = "A mapping of tags to assign to the Container Apps Environment"
  type        = map(string)
  default     = {}
}

variable "container_apps_environment_enable_private_endpoint" {
  description = "Should a private endpoint be created for the Container Apps Environment"
  type        = bool
  default     = false
}

variable "container_apps_environment_private_endpoint_subnet_name" {
  description = "The name of the subnet where the private endpoint should be created"
  type        = string
  default     = "snet-private-endpoint-services-001"
}

variable "container_apps_environment_private_endpoint_name" {
  description = "The name of the private endpoint. If null, a default name will be generated"
  type        = string
  default     = null
}

variable "container_apps_environment_private_endpoint_connection_name" {
  description = "The name of the private endpoint connection. If null, a default name will be generated"
  type        = string
  default     = null
}

variable "container_apps_environment_private_dns_zone_ids" {
  description = "List of private DNS zone IDs for the Container Apps Environment private endpoint"
  type        = list(string)
  default     = []
}


# ============================================================================
# AZURE API MANAGEMENT VARIABLES
# ============================================================================

variable "apim_enabled" {
  description = "Whether to deploy Azure API Management"
  type        = bool
  default     = false
}

variable "apim_name" {
  description = "Name of the API Management instance"
  type        = string
  default     = ""
}

variable "apim_publisher_name" {
  description = "Publisher name shown in the developer portal"
  type        = string
  default     = "Agent Migration Team"
}

variable "apim_publisher_email" {
  description = "Publisher email for notifications"
  type        = string
  default     = "apim@contoso.com"
}

variable "apim_sku_name" {
  description = "SKU tier for API Management"
  type        = string
  default     = "Developer"

  validation {
    condition     = contains(["Developer", "Basic", "Standard", "Premium"], var.apim_sku_name)
    error_message = "SKU must be Developer, Basic, Standard, or Premium."
  }
}

variable "apim_capacity" {
  description = "Number of scale units for APIM"
  type        = number
  default     = 1
}

variable "apim_virtual_network_type" {
  description = "VNet integration mode: None, External, or Internal"
  type        = string
  default     = "External"

  validation {
    condition     = contains(["None", "External", "Internal"], var.apim_virtual_network_type)
    error_message = "Must be None, External, or Internal."
  }
}

variable "apim_public_network_access" {
  description = "Allow or block public traffic to APIM gateway"
  type        = string
  default     = "Enabled"

  validation {
    condition     = contains(["Enabled", "Disabled"], var.apim_public_network_access)
    error_message = "Must be Enabled or Disabled."
  }
}

variable "apim_subnet_name" {
  description = "Name of the subnet for APIM VNet integration"
  type        = string
  default     = "snet-apim-001"
}

variable "apim_enable_diagnostic_settings" {
  description = "Enable diagnostic settings (logs + metrics) for APIM"
  type        = bool
  default     = false
}

variable "apim_diagnostic_setting_name" {
  description = "Name of the diagnostic setting"
  type        = string
  default     = "apim-diagnostics"
}

variable "apim_tags" {
  description = "Additional tags for the APIM instance"
  type        = map(string)
  default     = {}
}

variable "apim_public_ip_name" {
  description = "Resource ID of a public IP to assign to APIM (required for External VNet mode)"
  type        = string
  default     = null
}

variable "apim_nsg_enabled" {
  description = "Whether to create and associate an NSG for the APIM subnet"
  type        = bool
  default     = true
}

variable "apim_nsg_name" {
  description = "Name of the NSG. Leave empty to auto-generate from apim_name"
  type        = string
  default     = ""
}

variable "apim_nsg_tags" {
  description = "Additional tags for the APIM NSG"
  type        = map(string)
  default     = {}
}

variable "apim_deploy_apis" {
  description = "Whether to deploy APIs into APIM (requires apim_enabled = true)"
  type        = bool
  default     = false
}

# ==============================================================================
# MCP Server Configuration
# ==============================================================================

variable "mcp_enabled" {
  description = "Whether to expose the APIM API as an MCP server (requires apim_deploy_apis = true)"
  type        = bool
  default     = false
}

variable "mcp_server_name" {
  description = "Name identifier for the MCP server API resource in APIM"
  type        = string
  default     = "modernizer-mcp"
}

variable "mcp_display_name" {
  description = "Display name of the MCP server shown in APIM and MCP clients"
  type        = string
  default     = "Code Modernizer MCP"
}

variable "mcp_description" {
  description = "Description of the MCP server"
  type        = string
  default     = "MCP server exposing the Code Modernizer Agent API operations as tools"
}

variable "mcp_path" {
  description = "Base path for the MCP server endpoint (endpoint will be at {gateway_url}/{mcp_path}/mcp)"
  type        = string
  default     = "modernizer-mcp"
}

variable "mcp_tools" {
  description = "Map of MCP tools to create. Each tool maps an APIM API operation to an MCP tool"
  type = map(object({
    display_name = string
    description  = string
    api_key      = string
    operation_id = string
  }))
  default = {}
}