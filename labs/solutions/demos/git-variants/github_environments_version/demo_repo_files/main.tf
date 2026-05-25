resource "azurerm_resource_group" "demo" {
  name     = var.rg_name
  location = var.location
  tags = {
    Environment = var.environment,
    Comment     = "change 1"
  }
}
