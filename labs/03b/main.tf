provider "azurerm" {
  subscription_id = "<subscription id>"
  features {}
}

resource "azurerm_resource_group" "RG_demo" {
  name     = "RG2"
  location = "West Europe"
}