output "foundry_id" {
  description = "Resource ID of the AI Foundry account"
  value       = azapi_resource.foundry.id
}

output "foundry_name" {
  description = "Name of the AI Foundry account"
  value       = azapi_resource.foundry.name
}

output "project_id" {
  description = "Resource ID of the AI Foundry Project"
  value       = azapi_resource.project.id
}

output "project_name" {
  description = "Name of the AI Foundry Project"
  value       = azapi_resource.project.name
}

output "project_principal_id" {
  description = "Principal ID of the AI Foundry Project managed identity"
  value       = azapi_resource.project.output.identity.principalId
}

output "project_endpoint" {
  description = "AI Foundry API endpoint for the project"
  value       = azapi_resource.project.output.properties.endpoints["AI Foundry API"]
}

output "foundry_principal_id" {
  description = "Principal ID of the AI Foundry account managed identity"
  value       = azapi_resource.foundry.output.identity.principalId
}

output "openai_endpoint" {
  description = "OpenAI Language Model Instance API endpoint"
  value       = azapi_resource.foundry.output.properties.endpoints["OpenAI Language Model Instance API"]
}

output "deployment_name" {
  description = "Name of the model deployment"
  value       = azapi_resource.model_deployment.name
}

output "capability_host_id" {
  description = "Resource ID of the Agents Capability Host"
  value       = azapi_resource.capability_host.id
}

output "app_insights_connection_id" {
  description = "Resource ID of the Application Insights connection"
  value       = azapi_resource.app_insights_connection.id
}
