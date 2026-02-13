variable "foundry_name" {
  description = "Name of the AI Foundry Cognitive Services account"
  type        = string
}

variable "project_name" {
  description = "Name of the AI Foundry Project"
  type        = string
}

variable "capability_host_name" {
  description = "Name of the Agents Capability Host"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "resource_group_id" {
  description = "Resource ID of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Model deployment variables
variable "model_name" {
  description = "Name of the AI model to deploy"
  type        = string
}

variable "model_format" {
  description = "Format of the AI model"
  type        = string
}

variable "model_version" {
  description = "Version of the AI model"
  type        = string
}

variable "model_sku_name" {
  description = "SKU name for the model deployment"
  type        = string
}

variable "model_capacity" {
  description = "Capacity for the model deployment"
  type        = number
}

# Application Insights connection variables
variable "application_insights_id" {
  description = "Resource ID of Application Insights"
  type        = string
}

variable "application_insights_connection_string" {
  description = "Connection string for Application Insights"
  type        = string
  sensitive   = true
}

# Connection names
variable "appi_connection_name" {
  description = "Name of the Application Insights connection"
  type        = string
  default     = "appi-connection"
}
