# Random string for resource token seed (when timestamp not provided)
resource "random_string" "timestamp" {
  count   = var.timestamp == "" ? 1 : 0
  length  = 14
  special = false
  upper   = false
  numeric = true
}

# --- Container Registry (Azure Verified Module) ---

module "container_registry" {
  source  = "Azure/avm-res-containerregistry-registry/azurerm"
  version = "0.5.1"

  name                    = "acr${local.resource_token}"
  resource_group_name     = local.resource_group.name
  location                = var.location
  sku                     = var.acr_sku
  zone_redundancy_enabled = var.acr_zone_redundancy_enabled
  enable_telemetry        = var.enable_telemetry
  tags                    = merge({ "azd-env-name" = var.environment_name, "managed-by" = "terraform" }, var.tags)
}

# --- Monitoring (Log Analytics + Application Insights) ---

module "monitoring" {
  source = "./modules/monitoring"

  log_analytics_name        = "logs-${local.resource_token}"
  application_insights_name = "appi-${local.resource_token}"
  resource_group_name       = local.resource_group.name
  location                  = var.location
  tags                      = merge({ "azd-env-name" = var.environment_name, "managed-by" = "terraform" }, var.tags)
}

# --- AI Foundry (Account + Project + CapabilityHost + Model + AppInsights connection) ---

module "ai_foundry" {
  source = "./modules/ai-foundry"

  foundry_name         = "foundry${local.resource_token}"
  project_name         = var.project_name
  capability_host_name = var.capability_host_name
  resource_group_name  = local.resource_group.name
  resource_group_id    = local.resource_group.id
  location             = var.location
  tags                 = merge({ "azd-env-name" = var.environment_name, "managed-by" = "terraform" }, var.tags)

  model_name     = var.model_name
  model_format   = var.model_format
  model_version  = var.model_version
  model_sku_name = var.model_sku_name
  model_capacity = var.model_capacity

  application_insights_id                = module.monitoring.application_insights_id
  application_insights_connection_string = module.monitoring.application_insights_connection_string
  appi_connection_name                   = var.appi_connection_name

  depends_on = [module.monitoring]
}

# --- User Assigned Managed Identity (for Container App → ACR + Foundry) ---

module "agent_identity" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "0.3.4"

  name                = "id-${var.agent_name}"
  location            = var.location
  resource_group_name = local.resource_group.name
  enable_telemetry    = var.enable_telemetry
  tags                = merge({ "azd-env-name" = var.environment_name, "managed-by" = "terraform" }, var.tags)
}

# --- RBAC Role Assignments (Azure Verified Module) ---

module "role_assignments" {
  source  = "Azure/avm-res-authorization-roleassignment/azurerm"
  version = "0.3.0"

  enable_telemetry = var.enable_telemetry

  role_assignments_azure_resource_manager = {
    # ACR Pull — Project managed identity → ACR
    acr_pull = {
      principal_id                     = module.ai_foundry.project_principal_id
      role_definition_name             = "AcrPull"
      scope                            = module.container_registry.resource_id
      principal_type                   = "ServicePrincipal"
      description                      = "Allow AI Foundry Project to pull images from ACR"
      skip_service_principal_aad_check = true
    }
    # ACR Push — Deployer → ACR
    acr_push = {
      principal_id         = data.azurerm_client_config.current.object_id
      role_definition_name = "AcrPush"
      scope                = module.container_registry.resource_id
      principal_type       = "User"
      description          = "Allow deployer to push images to ACR"
    }
    # Azure AI User — Deployer → Foundry (data actions: agents/write, traces, etc.)
    azure_ai_user = {
      principal_id         = data.azurerm_client_config.current.object_id
      role_definition_name = "Azure AI User"
      scope                = module.ai_foundry.foundry_id
      principal_type       = "User"
      description          = "Allow deployer to use Foundry data plane (agents, deployments)"
    }
    # Cognitive Services User — Project managed identity → Foundry
    cognitive_services_user = {
      principal_id                     = module.ai_foundry.project_principal_id
      role_definition_name             = "Cognitive Services User"
      scope                            = module.ai_foundry.foundry_id
      principal_type                   = "ServicePrincipal"
      description                      = "Allow AI Foundry Project to use Cognitive Services"
      skip_service_principal_aad_check = true
    }
    # Azure AI User — Project managed identity → Foundry (data plane access)
    azure_ai_user_project = {
      principal_id                     = module.ai_foundry.project_principal_id
      role_definition_name             = "Azure AI User"
      scope                            = module.ai_foundry.foundry_id
      principal_type                   = "ServicePrincipal"
      description                      = "Allow AI Foundry Project data plane access"
      skip_service_principal_aad_check = true
    }
    # -------------------------------------------------------------------
    # Container App UAMI → ACR + Foundry
    # -------------------------------------------------------------------
    # AcrPull — Container App UAMI → ACR
    ca_acr_pull = {
      principal_id                     = module.agent_identity.principal_id
      role_definition_name             = "AcrPull"
      scope                            = module.container_registry.resource_id
      principal_type                   = "ServicePrincipal"
      description                      = "Allow Container App UAMI to pull images from ACR"
      skip_service_principal_aad_check = true
    }
    # Cognitive Services User — Container App UAMI → Foundry
    ca_cognitive_services_user = {
      principal_id                     = module.agent_identity.principal_id
      role_definition_name             = "Cognitive Services User"
      scope                            = module.ai_foundry.foundry_id
      principal_type                   = "ServicePrincipal"
      description                      = "Allow Container App UAMI to use Cognitive Services"
      skip_service_principal_aad_check = true
    }
    # Azure AI User — Container App UAMI → Foundry (data plane access)
    ca_azure_ai_user = {
      principal_id                     = module.agent_identity.principal_id
      role_definition_name             = "Azure AI User"
      scope                            = module.ai_foundry.foundry_id
      principal_type                   = "ServicePrincipal"
      description                      = "Allow Container App UAMI to use Foundry data plane"
      skip_service_principal_aad_check = true
    }
  }

  depends_on = [
    module.container_registry,
    module.ai_foundry,
    module.agent_identity,
  ]
}


# --- Virtual Network ---

module "azure-virtual-networks" {
  source = "./modules/azure-virtual-networks"

  virtual_network_exists        = var.virtual_network_exists
  azure_bastion_exists          = var.azure_bastion_exists
  virtual_network_name          = var.virtual_network_name
  resource_group_name           = local.resource_group.name
  location                      = var.location
  virtual_network_address_space = var.virtual_network_address_space
  virtual_network_subnets       = var.virtual_network_subnets
  tags                          = merge({ "azd-env-name" = var.environment_name, "managed-by" = "terraform" }, var.tags)
}

# --- Container Apps Environment ---

module "azure-container-apps-environments" {
  source = "./modules/azure-container-apps-environments"

  # Core configuration
  name                = var.container_apps_environment_name
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  resource_group_id   = local.resource_group.id

  # Public network access
  public_network_access = var.container_apps_environment_public_network_access

  # Network configuration
  infrastructure_subnet_id       = module.azure-virtual-networks.subnet_ids[var.container_apps_environment_infrastructure_subnet_name]
  internal_load_balancer_enabled = var.container_apps_environment_internal_load_balancer_enabled
  zone_redundancy_enabled        = var.container_apps_environment_zone_redundancy_enabled

  # Log Analytics configuration
  log_analytics_workspace_id          = module.monitoring.log_analytics_workspace_id
  log_analytics_workspace_customer_id = module.monitoring.log_analytics_workspace_customer_id
  log_analytics_workspace_shared_key  = module.monitoring.log_analytics_workspace_shared_key

  # Security configuration
  mutual_tls_enabled                            = var.container_apps_environment_mutual_tls_enabled
  peer_traffic_encryption_enabled               = var.container_apps_environment_peer_traffic_encryption_enabled
  dapr_application_insights_connection_string    = var.container_apps_environment_dapr_application_insights_connection_string
  dapr_application_insights_instrumentation_key  = var.container_apps_environment_dapr_application_insights_instrumentation_key

  # Workload profiles
  workload_profile = var.container_apps_environment_workload_profile

  # Private endpoint configuration
  enable_private_endpoint          = var.container_apps_environment_enable_private_endpoint
  private_endpoint_name            = var.container_apps_environment_private_endpoint_name
  private_endpoint_subnet_id       = var.container_apps_environment_enable_private_endpoint ? module.azure-virtual-networks.subnet_ids[var.container_apps_environment_private_endpoint_subnet_name] : null
  private_endpoint_connection_name = var.container_apps_environment_private_endpoint_connection_name
  private_dns_zone_ids             = var.container_apps_environment_private_dns_zone_ids

  # Tags
  tags = var.container_apps_environment_tags

  depends_on = [
    module.monitoring,
    module.azure-virtual-networks,
  ]
}

# ==============================================================================
# Network Security Group for API Management
# ==============================================================================
# NSG with all required rules for APIM VNet integration (External mode)
# Reference: https://learn.microsoft.com/en-us/azure/api-management/api-management-using-with-vnet
module "nsg_apim" {
  count  = var.apim_enabled && var.apim_nsg_enabled && var.apim_virtual_network_type != "None" ? 1 : 0
  source = "./modules/azure-nsg-apim"

  name                = var.apim_nsg_name != "" ? var.apim_nsg_name : "${local.apim_name_unique}-nsg"
  location            = var.location
  resource_group_name = local.resource_group.name
  subnet_id           = module.azure-virtual-networks.subnet_ids[var.apim_subnet_name]

  tags = merge({ "azd-env-name" = var.environment_name, "managed-by" = "terraform" }, var.apim_nsg_tags)

  depends_on = [
    module.azure-virtual-networks,
  ]
}

# ==============================================================================
# Azure API Management Module Definition
# ==============================================================================
# Configured for public access with VNet integration in External mode
# - Developer SKU for development environment
# - System-assigned managed identity
# - Dedicated public IP address
# - Integration with VNet subnet snet-apim-services-001
# - Diagnostic settings enabled for monitoring
module "avm-res-apimanagement-service" {
  count   = var.apim_enabled ? 1 : 0
  source  = "Azure/avm-res-apimanagement-service/azurerm"
  version = "0.0.5"

  # Required parameters
  location            = var.location
  name                = local.apim_name_unique
  resource_group_name = local.resource_group.name
  publisher_email     = var.apim_publisher_email
  publisher_name      = var.apim_publisher_name

  # SKU configuration — format: "SKU_Capacity"
  sku_name = "${var.apim_sku_name}_${var.apim_capacity}"

  # Identity configuration
  managed_identities = {
    system_assigned = true
  }

  # Public IP — required for External VNet mode, null for Internal
  public_ip_address_id = var.apim_virtual_network_type != "Internal" ? var.apim_public_ip_name : null

  # Virtual network configuration
  virtual_network_type          = var.apim_virtual_network_type
  public_network_access_enabled = var.apim_public_network_access == "Enabled"

  virtual_network_subnet_id = var.apim_virtual_network_type != "None" ? module.azure-virtual-networks.subnet_ids[var.apim_subnet_name] : null

  # Diagnostic settings for monitoring
  diagnostic_settings = var.apim_enable_diagnostic_settings ? {
    apim_diagnostics = {
      name                  = var.apim_diagnostic_setting_name
      workspace_resource_id = module.monitoring.log_analytics_workspace_id
      log_categories        = ["GatewayLogs", "WebSocketConnectionLogs"]
      metric_categories     = ["AllMetrics"]
    }
  } : {}

  # Tags
  tags = merge({ "azd-env-name" = var.environment_name, "managed-by" = "terraform" }, var.apim_tags)

  # Dependencies
  depends_on = [
    module.monitoring,
    module.azure-virtual-networks,
    module.nsg_apim,
  ]
}

# ==============================================================================
# API Management — APIs Deployment (OpenAPI import + policies)
# ==============================================================================

module "apim_apis" {
  count  = var.apim_enabled && var.apim_deploy_apis ? 1 : 0
  source = "./modules/azure-apim-apis-deployment"

  resource_group_name = local.resource_group.name
  apim_name           = local.apim_name_unique
  tenant_id           = data.azurerm_client_config.current.tenant_id

  # Backend URL del Container App — se inyecta automáticamente en las políticas XML
  default_backend_url = "https://${var.agent_name}.${module.azure-container-apps-environments.default_domain}"

  backend_apis = {
    agents-api = {
      name             = "agents-api"
      display_name     = "Code Modernizer Agent API"
      path             = "modernizer"
      protocols        = ["https"]
      openapi_format   = "openapi"
      openapi_content  = file("${path.root}/../../AIAppsModernization/openapi.yaml")
      backend_url      = ""

      jwt_enabled         = false
      jwt_audience        = ""
      jwt_issuer          = ""
      jwt_required_claims = {}

      rate_limit_calls  = 100
      rate_limit_period = 60

      subscription_required   = false
      subscription_key_header = "Ocp-Apim-Subscription-Key"
      subscription_key_query  = "subscription-key"
    }
  }

  # MCP Server — expone la API como servidor MCP (Streamable HTTP)
  mcp_enabled           = var.mcp_enabled
  mcp_server_name       = var.mcp_server_name
  mcp_display_name      = var.mcp_display_name
  mcp_description       = var.mcp_description
  mcp_path              = var.mcp_path
  mcp_tools             = var.mcp_tools

  depends_on = [
    module.avm-res-apimanagement-service,
    module.azure-container-apps-environments,
  ]
}