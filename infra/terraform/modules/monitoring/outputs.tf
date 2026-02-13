output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.workspace.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.workspace.name
}

output "application_insights_id" {
  description = "Resource ID of Application Insights"
  value       = azurerm_application_insights.app_insights.id
}

output "application_insights_name" {
  description = "Name of Application Insights"
  value       = azurerm_application_insights.app_insights.name
}

output "application_insights_connection_string" {
  description = "Connection string for Application Insights"
  value       = azurerm_application_insights.app_insights.connection_string
  sensitive   = true
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = azurerm_application_insights.app_insights.instrumentation_key
  sensitive   = true
}

output "log_analytics_workspace_customer_id" {
  description = "Customer ID (workspace ID) of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.workspace.workspace_id
}

output "log_analytics_workspace_shared_key" {
  description = "Primary shared key of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.workspace.primary_shared_key
  sensitive   = true
}
