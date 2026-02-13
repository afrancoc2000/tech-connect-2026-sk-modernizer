locals {
  # Unified resource group reference (whether created or existing)
  resource_group = var.create_resource_group ? azurerm_resource_group.new[0] : data.azurerm_resource_group.existing[0]

  # Resource token — 13-char hash for globally unique names
  resource_token = lower(substr(
    sha256("${local.resource_group.id}${var.environment_name}${var.location}${var.timestamp != "" ? var.timestamp : (length(random_string.timestamp) > 0 ? random_string.timestamp[0].result : "")}"),
    0,
    13,
  ))

  # APIM name with random suffix for global uniqueness (max 50 chars)
  apim_name_unique = var.apim_name != "" ? "${var.apim_name}-${substr(local.resource_token, 0, 6)}" : ""
}
