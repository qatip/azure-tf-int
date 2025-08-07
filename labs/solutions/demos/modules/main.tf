terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.38.1"
    }
  }
}

provider "azurerm" {
  subscription_id = "<sub id>"
  features {}
}
module "vnet" {
  source  = "Azure/vnet/azurerm"
  version = "5.0.1"
  vnet_location = "West Europe"
  resource_group_name = "demo-rg"

}
