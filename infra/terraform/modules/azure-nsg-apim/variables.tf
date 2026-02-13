# ==============================================================================
# Azure NSG for API Management - Variables
# ==============================================================================
# This module creates a Network Security Group (NSG) with all required rules
# for Azure API Management VNet integration (External mode)
# Based on: https://learn.microsoft.com/en-us/azure/api-management/api-management-using-with-vnet

variable "name" {
  description = "Name of the Network Security Group"
  type        = string
}

variable "location" {
  description = "Azure region where the NSG will be created"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet to associate the NSG with"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the NSG"
  type        = map(string)
  default     = {}
}
