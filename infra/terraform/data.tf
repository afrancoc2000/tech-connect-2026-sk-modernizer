# Data sources for current deployment context
data "azurerm_client_config" "current" {}

# Resource group — conditional create vs read
data "azurerm_resource_group" "existing" {
  count = var.create_resource_group ? 0 : 1
  name  = var.resource_group_name
}

resource "azurerm_resource_group" "new" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location

  tags = merge(
    { "azd-env-name" = var.environment_name, "managed-by" = "terraform" },
    var.tags,
  )
}
