# ==============================================================================
# Network Security Group for Azure API Management (External VNet Mode)
# ==============================================================================
# This NSG contains all required rules for APIM VNet integration
# Reference: https://learn.microsoft.com/en-us/azure/api-management/api-management-using-with-vnet

resource "azurerm_network_security_group" "apim" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# ==============================================================================
# INBOUND RULES
# ==============================================================================

# Inbound: Client communication to API Management (External only)
# Port 80, 443 from Internet
resource "azurerm_network_security_rule" "inbound_client_communication" {
  name                        = "AllowClientCommunication"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = "Internet"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.apim.name
}

# Inbound: Management endpoint for Azure portal and PowerShell
# Port 3443 from ApiManagement service tag
resource "azurerm_network_security_rule" "inbound_management_endpoint" {
  name                        = "AllowManagementEndpoint"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3443"
  source_address_prefix       = "ApiManagement"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.apim.name
}

# Inbound: Azure Infrastructure Load Balancer
# Port 6390 from AzureLoadBalancer
resource "azurerm_network_security_rule" "inbound_load_balancer" {
  name                        = "AllowAzureLoadBalancer"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "6390"
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.apim.name
}

# Inbound: Azure Traffic Manager (External only)
# Port 443 from AzureTrafficManager
resource "azurerm_network_security_rule" "inbound_traffic_manager" {
  name                        = "AllowTrafficManager"
  priority                    = 130
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "AzureTrafficManager"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.apim.name
}

# ==============================================================================
# OUTBOUND RULES
# ==============================================================================

# Outbound: Certificate validation and management
# Port 80 to Internet
resource "azurerm_network_security_rule" "outbound_certificate_validation" {
  name                        = "AllowCertificateValidation"
  priority                    = 200
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "Internet"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.apim.name
}

# Outbound: Azure Storage dependency
# Port 443 to Storage
resource "azurerm_network_security_rule" "outbound_storage" {
  name                        = "AllowAzureStorage"
  priority                    = 210
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "Storage"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.apim.name
}

# Outbound: Azure SQL dependency
# Port 1433 to SQL
resource "azurerm_network_security_rule" "outbound_sql" {
  name                        = "AllowAzureSQL"
  priority                    = 220
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "1433"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "Sql"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.apim.name
}

# Outbound: Azure Key Vault dependency
# Port 443 to AzureKeyVault
resource "azurerm_network_security_rule" "outbound_keyvault" {
  name                        = "AllowAzureKeyVault"
  priority                    = 230
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "AzureKeyVault"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.apim.name
}

# Outbound: Azure Monitor (Diagnostics, Metrics, Application Insights)
# Ports 1886, 443 to AzureMonitor
resource "azurerm_network_security_rule" "outbound_monitor" {
  name                        = "AllowAzureMonitor"
  priority                    = 240
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["1886", "443"]
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "AzureMonitor"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.apim.name
}


# TLS/OCSP/CRL por HTTPS
resource "azurerm_network_security_rule" "outbound_certificate_validation_https" {
  name                        = "AllowCertificateValidationHTTPS"
  priority                    = 201
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "Internet"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.apim.name
}

# Microsoft Entra ID / Graph
resource "azurerm_network_security_rule" "outbound_aad" {
  name                        = "AllowAzureActiveDirectory"
  priority                    = 215
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "AzureActiveDirectory"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.apim.name
}

# Outbound: Azure Event Hubs dependency (Log to Event Hubs policy)
# Ports 5671, 5672, 443 to EventHub
resource "azurerm_network_security_rule" "outbound_eventhub" {
  name                        = "AllowAzureEventHub"
  priority                    = 250
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["5671", "5672", "443"]
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "EventHub"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.apim.name
}

# Outbound: Azure Connectors dependency (managed connections)
# Port 443 to AzureConnectors
resource "azurerm_network_security_rule" "outbound_connectors" {
  name                        = "AllowAzureConnectors"
  priority                    = 260
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "AzureConnectors"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.apim.name
}

# ==============================================================================
# NSG Association to Subnet
# ==============================================================================

resource "azurerm_subnet_network_security_group_association" "apim" {
  subnet_id                 = var.subnet_id
  network_security_group_id = azurerm_network_security_group.apim.id
}
