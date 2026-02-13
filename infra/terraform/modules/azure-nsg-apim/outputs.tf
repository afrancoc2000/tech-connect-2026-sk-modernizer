# ==============================================================================
# Outputs for Azure NSG APIM Module
# ==============================================================================

output "id" {
  description = "The ID of the Network Security Group"
  value       = azurerm_network_security_group.apim.id
}

output "name" {
  description = "The name of the Network Security Group"
  value       = azurerm_network_security_group.apim.name
}

output "location" {
  description = "The location of the Network Security Group"
  value       = azurerm_network_security_group.apim.location
}
