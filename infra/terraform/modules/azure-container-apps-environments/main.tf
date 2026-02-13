# ------------------------------------------------------------------------------
# Main Container Apps Environment Resource - Using AzAPI for 2025-01-01 support
# Note: schema_validation_enabled = false to disable strict API validation
# -----------------------------------------------------------------------------------------------------------------------------------------------------------
# Main Container Apps Environment Resource - Using AzAPI for 2025-07-01 support
# ------------------------------------------------------------------------------

resource "azapi_resource" "main" {
  type                      = "Microsoft.App/managedEnvironments@2025-07-01"
  name                      = var.name
  location                  = var.location
  parent_id                 = var.resource_group_id
  schema_validation_enabled = false

  # Identity configuration
  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" || var.identity_type == "SystemAssigned,UserAssigned" ? var.identity_ids : null
    }
  }

  body = {
    properties = {
      # Public network access configuration - natively supported in 2025-07-01
      publicNetworkAccess = var.public_network_access

      # App logs configuration
      appLogsConfiguration = var.log_analytics_workspace_id != null ? {
        destination = "log-analytics"
        logAnalyticsConfiguration = {
          customerId = var.log_analytics_workspace_customer_id
          sharedKey  = var.log_analytics_workspace_shared_key
        }
      } : null

      # VNet configuration
      vnetConfiguration = var.infrastructure_subnet_id != null ? {
        infrastructureSubnetId = var.infrastructure_subnet_id
        internal              = var.internal_load_balancer_enabled
        dockerBridgeCidr      = var.docker_bridge_cidr
        platformReservedCidr  = var.platform_reserved_cidr
        platformReservedDnsIP = var.platform_reserved_dns_ip
      } : null

      # Zone redundancy
      zoneRedundant = var.zone_redundancy_enabled

      # Infrastructure resource group
      infrastructureResourceGroup = var.infrastructure_resource_group_name

      # Workload profiles - only include supported properties per profile type
      workloadProfiles = var.workload_profile != null ? [
        for profile in var.workload_profile :
        profile.workloadProfileType == "Consumption" ? {
          name                = profile.name
          workloadProfileType = profile.workloadProfileType
        } : {
          name                = profile.name
          workloadProfileType = profile.workloadProfileType
          minimumCount        = profile.minimumCount
          maximumCount        = profile.maximumCount
        }
      ] : []

      # Dapr configuration
      daprAIConnectionString     = var.dapr_application_insights_connection_string
      daprAIInstrumentationKey  = var.dapr_application_insights_instrumentation_key

      # Peer authentication (mutual TLS)
      peerAuthentication = var.mutual_tls_enabled ? {
        mtls = {
          enabled = var.mutual_tls_enabled
        }
      } : null

      # Peer traffic encryption
      peerTrafficConfiguration = var.peer_traffic_encryption_enabled ? {
        encryption = {
          enabled = var.peer_traffic_encryption_enabled
        }
      } : null

      # Custom domain configuration
      customDomainConfiguration = var.custom_domain_configuration

      # Ingress configuration
      ingressConfiguration = var.ingress_configuration
    }
  }

  tags = var.tags

  # Response export values for accessing computed properties
  response_export_values = [
    "properties.defaultDomain",
    "properties.staticIp",
    "properties.customDomainVerificationId"
  ]

  # Lifecycle management
  lifecycle {
    prevent_destroy = false
    ignore_changes  = [tags]
  }
}

# ------------------------------------------------------------------------------
# Private Endpoint for Container Apps Environment
# ------------------------------------------------------------------------------

resource "azurerm_private_endpoint" "container_apps_environment" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = var.private_endpoint_name != null ? var.private_endpoint_name : "${var.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = var.private_endpoint_connection_name != null ? var.private_endpoint_connection_name : "${var.name}-pe-connection"
    private_connection_resource_id = azapi_resource.main.id
    is_manual_connection           = false
    subresource_names              = ["managedEnvironments"]
  }

  # Private DNS zone group configuration
  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_ids != null && length(var.private_dns_zone_ids) > 0 ? [1] : []
    content {
      name                 = var.private_dns_zone_group_name != null ? var.private_dns_zone_group_name : "default"
      private_dns_zone_ids = var.private_dns_zone_ids
    }
  }

  tags = var.tags

  depends_on = [azapi_resource.main]
}

# ------------------------------------------------------------------------------
# Container Apps Environment Storage (Optional)
# ------------------------------------------------------------------------------

# Note: Container Apps Environment Storage is typically managed separately
# but can be included here if needed. This would be used for mounting
# Azure Files or other storage types to containers.

# Example storage configuration (commented out):
# resource "azurerm_container_app_environment_storage" "example" {
#   name                         = "example-storage"
#   container_app_environment_id = azurerm_container_app_environment.main.id
#   account_name                = "mystorageaccount"
#   share_name                  = "myshare"
#   access_key                  = "storageaccountaccesskey"
#   access_mode                 = "ReadWrite"
# }

# ------------------------------------------------------------------------------
# Container Apps Environment Certificate (Optional)
# ------------------------------------------------------------------------------

# Note: Certificates are typically managed separately but can be included
# if you want to manage them as part of the environment module.

# Example certificate configuration (commented out):
# resource "azurerm_container_app_environment_certificate" "example" {
#   name                         = "example-certificate"
#   container_app_environment_id = azurerm_container_app_environment.main.id
#   certificate_blob_base64      = filebase64("certificate.pfx")
#   certificate_password         = "certificatepassword"
# }
