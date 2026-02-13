# AI Foundry Module
# Creates Cognitive Services account, AI Project, Capability Host, Model Deployment, and App Insights connection
# Note: No MCP connection — agent-flow does not require remote tool connections

# AI Foundry Cognitive Services Account
resource "azapi_resource" "foundry" {
  type                      = "Microsoft.CognitiveServices/accounts@2025-10-01-preview"
  name                      = var.foundry_name
  location                  = var.location
  parent_id                 = var.resource_group_id
  schema_validation_enabled = false

  response_export_values = [
    "identity.principalId",
    "properties.endpoints",
  ]

  identity {
    type = "SystemAssigned"
  }

  body = {
    sku = {
      name = "S0"
    }
    kind = "AIServices"
    properties = {
      allowProjectManagement = true
      customSubDomainName    = var.foundry_name
      networkAcls = {
        defaultAction       = "Allow"
        virtualNetworkRules = []
        ipRules             = []
      }
      publicNetworkAccess = "Enabled"
      disableLocalAuth    = false
    }
  }

  tags = var.tags
}

# AI Foundry Project (child resource)
resource "azapi_resource" "project" {
  type                      = "Microsoft.CognitiveServices/accounts/projects@2025-10-01-preview"
  name                      = var.project_name
  location                  = var.location
  parent_id                 = azapi_resource.foundry.id
  schema_validation_enabled = false

  response_export_values = [
    "identity.principalId",
    "properties.endpoints",
  ]

  identity {
    type = "SystemAssigned"
  }

  body = {
    properties = {
      description = "Agent Flow Project"
      displayName = "Agent Flow"
    }
  }

  tags = var.tags

  depends_on = [azapi_resource.foundry]
}

# Agents Capability Host (child resource)
# Note: May cause Internal Server Error on redeployment — see Bicep comment
resource "azapi_resource" "capability_host" {
  type                      = "Microsoft.CognitiveServices/accounts/capabilityHosts@2025-10-01-preview"
  name                      = var.capability_host_name
  parent_id                 = azapi_resource.foundry.id
  schema_validation_enabled = false

  body = {
    properties = {
      capabilityHostKind             = "Agents"
      enablePublicHostingEnvironment = true
    }
  }

  depends_on = [azapi_resource.foundry]

  # Uncomment if experiencing issues with redeployment
  # lifecycle {
  #   ignore_changes = [body]
  # }
}

# Model Deployment (child resource)
resource "azapi_resource" "model_deployment" {
  type      = "Microsoft.CognitiveServices/accounts/deployments@2025-04-01-preview"
  name      = var.model_name
  parent_id = azapi_resource.foundry.id

  body = {
    sku = {
      capacity = var.model_capacity
      name     = var.model_sku_name
    }
    properties = {
      model = {
        name    = var.model_name
        format  = var.model_format
        version = var.model_version
      }
    }
  }

  depends_on = [azapi_resource.foundry]
}

# Application Insights Connection (grandchild resource)
resource "azapi_resource" "app_insights_connection" {
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview"
  name      = var.appi_connection_name
  parent_id = azapi_resource.project.id

  body = {
    properties = {
      category      = "AppInsights"
      target        = var.application_insights_id
      authType      = "ApiKey"
      isSharedToAll = true
      credentials = {
        key = var.application_insights_connection_string
      }
      metadata = {
        ApiType    = "Azure"
        ResourceId = var.application_insights_id
      }
    }
  }

  depends_on = [azapi_resource.project]
}
