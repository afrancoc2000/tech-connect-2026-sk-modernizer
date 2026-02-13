# ==============================================================================
# Azure Container App Environment Variables - AzAPI 2025-07-01
# ==============================================================================

# ------------------------------------------------------------------------------
# Core Variables
# ------------------------------------------------------------------------------

variable "name" {
  description = "Name of the Container Apps Environment"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,64}$", var.name))
    error_message = "The name must be between 1 and 64 characters and can only contain alphanumeric characters and hyphens."
  }
}

variable "location" {
  description = "Azure region where the resource will be created"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "resource_group_id" {
  description = "Resource ID of the resource group (parent_id for azapi_resource)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ------------------------------------------------------------------------------
# Public Network Access Configuration
# ------------------------------------------------------------------------------

variable "public_network_access" {
  description = "Property to allow or block all public traffic. Allowed values: 'Enabled', 'Disabled'"
  type        = string
  default     = "Disabled"
  validation {
    condition     = contains(["Enabled", "Disabled"], var.public_network_access)
    error_message = "public_network_access must be either 'Enabled' or 'Disabled'."
  }
}

# ------------------------------------------------------------------------------
# Log Analytics Configuration
# ------------------------------------------------------------------------------

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace resource ID for container logs"
  type        = string
  default     = null
}

variable "log_analytics_workspace_customer_id" {
  description = "Log Analytics workspace customer ID"
  type        = string
  default     = null
}

variable "log_analytics_workspace_shared_key" {
  description = "Log Analytics workspace shared key"
  type        = string
  default     = null
  sensitive   = true
}

# ------------------------------------------------------------------------------
# VNet Configuration
# ------------------------------------------------------------------------------

variable "infrastructure_subnet_id" {
  description = "Resource ID of subnet for infrastructure components"
  type        = string
  default     = null
}

variable "internal_load_balancer_enabled" {
  description = "Boolean indicating the environment only has an internal load balancer"
  type        = bool
  default     = false
}

variable "docker_bridge_cidr" {
  description = "CIDR notation IP range assigned to the Docker bridge network"
  type        = string
  default     = null
}

variable "platform_reserved_cidr" {
  description = "IP range in CIDR notation that can be reserved for environment infrastructure IP addresses"
  type        = string
  default     = null
}

variable "platform_reserved_dns_ip" {
  description = "An IP address from the IP range defined by platformReservedCidr that will be reserved for the internal DNS server"
  type        = string
  default     = null
}

# ------------------------------------------------------------------------------
# Infrastructure Configuration
# ------------------------------------------------------------------------------

variable "infrastructure_resource_group_name" {
  description = "Name of the platform-managed resource group created for the Managed Environment to host infrastructure resources"
  type        = string
  default     = null
}

variable "zone_redundancy_enabled" {
  description = "Whether or not this Managed Environment is zone-redundant"
  type        = bool
  default     = false
}

# ------------------------------------------------------------------------------
# Workload Profiles
# ------------------------------------------------------------------------------

variable "workload_profile" {
  description = "Workload profiles configured for the Managed Environment"
  type = list(object({
    name                 = string
    workloadProfileType  = string
    minimumCount         = optional(number)
    maximumCount         = optional(number)
  }))
  default = [
    {
      name                = "Consumption"
      workloadProfileType = "Consumption"
    }
  ]
}

# ------------------------------------------------------------------------------
# Dapr Configuration
# ------------------------------------------------------------------------------

variable "dapr_application_insights_connection_string" {
  description = "Application Insights connection string used by Dapr to export Service to Service communication telemetry"
  type        = string
  default     = null
  sensitive   = true
}

variable "dapr_application_insights_instrumentation_key" {
  description = "Azure Monitor instrumentation key used by Dapr to export Service to Service communication telemetry"
  type        = string
  default     = null
  sensitive   = true
}

# ------------------------------------------------------------------------------
# Security Configuration
# ------------------------------------------------------------------------------

variable "mutual_tls_enabled" {
  description = "Boolean indicating whether the mutual TLS authentication is enabled"
  type        = bool
  default     = false
}

variable "peer_traffic_encryption_enabled" {
  description = "Boolean indicating whether the peer traffic encryption is enabled"
  type        = bool
  default     = false
}

# ------------------------------------------------------------------------------
# Identity Configuration
# ------------------------------------------------------------------------------

variable "identity_type" {
  description = "Type of managed service identity. Allowed values: 'None', 'SystemAssigned', 'UserAssigned', 'SystemAssigned,UserAssigned'"
  type        = string
  default     = null
  validation {
    condition = var.identity_type == null || contains([
      "None", "SystemAssigned", "UserAssigned", "SystemAssigned,UserAssigned"
    ], var.identity_type)
    error_message = "identity_type must be one of: None, SystemAssigned, UserAssigned, SystemAssigned,UserAssigned."
  }
}

variable "identity_ids" {
  description = "List of User Assigned Managed Identity resource IDs to be assigned to the Container Apps Environment"
  type        = list(string)
  default     = []
}

# ------------------------------------------------------------------------------
# Optional Advanced Configuration
# ------------------------------------------------------------------------------

variable "custom_domain_configuration" {
  description = "Custom domain configuration for the environment"
  type = object({
    certificate_key_vault_properties = optional(object({
      identity     = string
      key_vault_url = string
    }))
    certificate_password = optional(string)
    certificate_value    = optional(string)
    dns_suffix          = optional(string)
  })
  default = null
}

variable "ingress_configuration" {
  description = "Ingress configuration for the Managed Environment"
  type = object({
    header_count_limit              = optional(number, 100)
    request_idle_timeout           = optional(number, 4)
    termination_grace_period_seconds = optional(number, 480)
    workload_profile_name          = string
  })
  default = null
}

# ------------------------------------------------------------------------------
# Private Endpoint Configuration
# ------------------------------------------------------------------------------

variable "enable_private_endpoint" {
  description = "Whether to create a private endpoint for the Container Apps Environment"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for the private endpoint"
  type        = string
  default     = null
}

variable "private_endpoint_name" {
  description = "Name of the private endpoint"
  type        = string
  default     = null
}

variable "private_endpoint_connection_name" {
  description = "Name of the private endpoint connection"
  type        = string
  default     = null
}

variable "private_dns_zone_ids" {
  description = "List of private DNS zone IDs to associate with the private endpoint"
  type        = list(string)
  default     = []
}

variable "private_dns_zone_group_name" {
  description = "The name of the private DNS zone group. If null, 'default' will be used"
  type        = string
  default     = null
}
