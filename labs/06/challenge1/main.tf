terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.18.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "<your subscription id>"
}

resource "azurerm_resource_group" "rg" {
  name     = <your code here>
  location = "West Europe"

  tags = {
    Environment = <your code here>
    CreatedOn   = <your code here>
  }
}