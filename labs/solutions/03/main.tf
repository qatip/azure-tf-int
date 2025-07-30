provider "azurerm" {
  subscription_id = "316f0ed4-2796-4561-a734-24b156826ae5"
  features {}
}

resource "azurerm_resource_group" "RG_demo" {
  name     = "RG2"
  location = "West Europe"
}
