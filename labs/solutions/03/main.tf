provider "azurerm" {
  subscription_id = "<sub_id>"
  features {}
}

resource "azurerm_resource_group" "RG_demo" {
  name     = "RG2"
  location = "West Europe"
}