resource "azurerm_resource_group" "rg" {
  name     = "${var.name_prefix}-rg-${var.env}"
  location = var.location
  tags = {
    environment = var.env
    managed_by  = "github-actions"
  }

# branch update
}
