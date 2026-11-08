terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.16.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "<subscription id>"
  features {}
}

resource "azurerm_resource_group" "RG_demo" {
  name     = "RG2"
  location = "denmarkeast"
}
