terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.16.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "<sub id>"
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "RG1"
  location = "East US"
}

module "vnet1" {
  source              = "./modules/vnet"
  vnet_name           = "vnet-01"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

module "vnet2" {
  source              = "./modules/vnet"
  vnet_name           = "vnet-02"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "subnet1" {
  name                 = "subnet-01"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = module.vnet1.vnet_name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "subnet2" {
  name                 = "subnet-02"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = module.vnet2.vnet_name
  address_prefixes     = ["10.1.1.0/24"]
}
