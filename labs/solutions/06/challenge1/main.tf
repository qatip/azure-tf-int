resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = "West Europe"

  tags = {
    Environment = upper(var.environment)
    CreatedOn   =formatdate("YYYY-MM-DD", timestamp())
  }
}

