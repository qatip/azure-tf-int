provider "azurerm" {
  subscription_id = "<your subscription id>"
  features {}
}

resource "azurerm_resource_group" "lab_rg" {
  name     = "RG1"
  location = "West Europe"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "lab-vnet"
  location            = azurerm_resource_group.lab_rg.location
  resource_group_name = azurerm_resource_group.lab_rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "lab-subnet"
  resource_group_name  = azurerm_resource_group.lab_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
