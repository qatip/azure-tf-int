terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.38.1"
    }
  }
}

provider "azurerm" {
  subscription_id = "316f0ed4-2796-4561-a734-24b156826ae5"
  features {}
}
module "vnet" {
  source  = "Azure/vnet/azurerm"
  version = "5.0.1"
  vnet_location = "West Europe"
  resource_group_name = "demo-rg"
}