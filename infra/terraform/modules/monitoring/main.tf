# Monitoring Module
# Creates Log Analytics workspace and Application Insights (no dashboard)

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "workspace" {
  name                = var.log_analytics_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# Application Insights
resource "azurerm_application_insights" "app_insights" {
  name                = var.application_insights_name
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.workspace.id
  tags                = var.tags
}
