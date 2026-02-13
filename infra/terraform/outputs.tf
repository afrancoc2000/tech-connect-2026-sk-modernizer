# --- Outputs consumed by postprovision.sh and curl ---

output "AZURE_OPENAI_ENDPOINT" {
  description = "OpenAI endpoint for the Foundry account"
  value       = module.ai_foundry.openai_endpoint
}

output "AZURE_OPENAI_CHAT_DEPLOYMENT_NAME" {
  description = "Name of the deployed chat model"
  value       = module.ai_foundry.deployment_name
}

output "AZURE_AI_PROJECT_ENDPOINT" {
  description = "AI Foundry project endpoint (used by agent runtime)"
  value       = module.ai_foundry.project_endpoint
}

output "APPLICATIONINSIGHTS_CONNECTION_STRING" {
  description = "Application Insights connection string"
  value       = module.monitoring.application_insights_connection_string
  sensitive   = true
}

output "AZURE_ACR_LOGIN_SERVER" {
  description = "ACR login server URL (for docker push / az acr build)"
  value       = module.container_registry.resource.login_server
}

output "AZURE_ACR_NAME" {
  description = "ACR name (for az acr build --registry)"
  value       = module.container_registry.name
}

output "AZURE_PROJECT_NAME" {
  description = "Foundry project name"
  value       = module.ai_foundry.project_name
}

output "AZURE_PROJECT_ID" {
  description = "Resource ID of the AI Foundry Project"
  value       = module.ai_foundry.project_id
}

output "AGENT_NAME" {
  description = "Container App name for the agent"
  value       = var.agent_name
}

output "AGENT_CPU" {
  description = "CPU allocation for the agent container"
  value       = var.agent_cpu
}

output "AGENT_MEMORY" {
  description = "Memory allocation for the agent container"
  value       = var.agent_memory
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = local.resource_group.name
}

output "environment_name" {
  description = "Environment name (dev, stg, prd)"
  value       = var.environment_name
}

# --- Container Apps Environment outputs ---

output "CONTAINER_APPS_ENVIRONMENT_NAME" {
  description = "Name of the Container Apps Environment"
  value       = module.azure-container-apps-environments.name
}

output "CONTAINER_APPS_ENVIRONMENT_ID" {
  description = "Resource ID of the Container Apps Environment"
  value       = module.azure-container-apps-environments.id
}

# --- User Assigned Managed Identity outputs ---

output "AGENT_IDENTITY_ID" {
  description = "Resource ID of the UAMI assigned to the Container App (for --mi-user-assigned)"
  value       = module.agent_identity.resource_id
}

output "AGENT_IDENTITY_CLIENT_ID" {
  description = "Client ID of the UAMI (for AZURE_CLIENT_ID env var in Container App)"
  value       = module.agent_identity.client_id
}

# --- Agent Base URL ---

output "AGENT_BASE_URL" {
  description = "Public HTTPS URL of the agent container app"
  value       = "https://${var.agent_name}.${module.azure-container-apps-environments.default_domain}"
}

# --- APIM outputs (conditional) ---

output "APIM_GATEWAY_URL" {
  description = "APIM gateway URL"
  value       = var.apim_enabled ? module.avm-res-apimanagement-service[0].resource.gateway_url : null
  sensitive   = true
}

output "APIM_NAME" {
  description = "Name of the API Management instance"
  value       = var.apim_enabled ? local.apim_name_unique : null
}
