# Azure Container App Environment Outputs - AzAPI 2025-07-01
# ==============================================================================

# ------------------------------------------------------------------------------
# Basic Resource Information
# ------------------------------------------------------------------------------

output "id" {
  description = "The ID of the Container Apps Environment"
  value       = azapi_resource.main.id
}

output "name" {
  description = "The name of the Container Apps Environment"
  value       = azapi_resource.main.name
}

output "location" {
  description = "The location of the Container Apps Environment"
  value       = azapi_resource.main.location
}

output "resource_group_name" {
  description = "The name of the resource group in which the Container Apps Environment is created"
  value       = var.resource_group_name
}

# ------------------------------------------------------------------------------
# Network and Infrastructure Information (from response_export_values)
# ------------------------------------------------------------------------------

output "default_domain" {
  description = "The default domain for the Container Apps Environment"
  value       = azapi_resource.main.output.properties.defaultDomain
}

output "static_ip" {
  description = "The static IP address for the Container Apps Environment"
  value       = try(azapi_resource.main.output.properties.staticIp, null)
}

# Note: customDomainVerificationId is not available in all API versions
# output "custom_domain_verification_id" {
#   description = "The custom domain verification ID for the Container Apps Environment"
#   value       = try(azapi_resource.main.output.properties.customDomainVerificationId, null)
# }

# ------------------------------------------------------------------------------
# Configuration Information
# ------------------------------------------------------------------------------

output "infrastructure_subnet_id" {
  description = "The infrastructure subnet ID used by the Container Apps Environment"
  value       = var.infrastructure_subnet_id
}

output "infrastructure_resource_group_name" {
  description = "The name of the infrastructure resource group"
  value       = var.infrastructure_resource_group_name
}

output "internal_load_balancer_enabled" {
  description = "Whether internal load balancer is enabled for the Container Apps Environment"
  value       = var.internal_load_balancer_enabled
}

output "zone_redundancy_enabled" {
  description = "Whether zone redundancy is enabled for the Container Apps Environment"
  value       = var.zone_redundancy_enabled
}

output "mutual_tls_enabled" {
  description = "Whether mutual TLS is enabled for the Container Apps Environment"
  value       = var.mutual_tls_enabled
}

output "public_network_access" {
  description = "The public network access setting for the Container Apps Environment"
  value       = var.public_network_access
}

# ------------------------------------------------------------------------------
# Logging and Monitoring Information
# ------------------------------------------------------------------------------

output "log_analytics_workspace_id" {
  description = "The Log Analytics workspace ID associated with the Container Apps Environment"
  value       = var.log_analytics_workspace_id
}

# ------------------------------------------------------------------------------
# Workload Profiles Information
# ------------------------------------------------------------------------------

output "workload_profile" {
  description = "The workload profiles configured for the Container Apps Environment"
  value       = var.workload_profile
}


# ------------------------------------------------------------------------------
# Tags and Metadata
# ------------------------------------------------------------------------------

output "tags" {
  description = "The tags assigned to the Container Apps Environment"
  value       = azapi_resource.main.tags
}


# ------------------------------------------------------------------------------
# Composite Outputs for Easy Reference
# ------------------------------------------------------------------------------

output "environment_fqdn" {
  description = "The fully qualified domain name of the Container Apps Environment"
  value       = azapi_resource.main.output.properties.defaultDomain
}

# ------------------------------------------------------------------------------
# Comprehensive Environment Information
# ------------------------------------------------------------------------------

output "environment_info" {
  description = "Comprehensive information about the Container Apps Environment"
  value = {
    id                                = azapi_resource.main.id
    name                              = azapi_resource.main.name
    location                          = azapi_resource.main.location
    resource_group_name               = var.resource_group_name
    default_domain                    = try(azapi_resource.main.output.properties.defaultDomain, null)
    static_ip                         = try(azapi_resource.main.output.properties.staticIp, null)
    internal_load_balancer_enabled    = var.internal_load_balancer_enabled
    zone_redundancy_enabled           = var.zone_redundancy_enabled
    mutual_tls_enabled                = var.mutual_tls_enabled
    infrastructure_subnet_id          = var.infrastructure_subnet_id
    log_analytics_workspace_id        = var.log_analytics_workspace_id
    public_network_access             = var.public_network_access
  }
}

# ------------------------------------------------------------------------------
# Outputs for Container Apps Deployment
# ------------------------------------------------------------------------------

output "container_app_environment_id" {
  description = "The ID of the Container Apps Environment for use in Container App deployments"
  value       = azapi_resource.main.id
}

output "environment_domain_suffix" {
  description = "The domain suffix for apps deployed in this environment"
  value       = azapi_resource.main.output.properties.defaultDomain
}

# ------------------------------------------------------------------------------
# Private Endpoint Outputs
# ------------------------------------------------------------------------------

output "private_endpoint_id" {
  description = "The ID of the private endpoint (if created)"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.container_apps_environment[0].id : null
}

output "private_endpoint_ip_address" {
  description = "The private IP address of the private endpoint (if created)"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.container_apps_environment[0].private_service_connection[0].private_ip_address : null
}

output "private_endpoint_fqdn" {
  description = "The FQDN of the private endpoint (if created)"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.container_apps_environment[0].custom_dns_configs : null
}


