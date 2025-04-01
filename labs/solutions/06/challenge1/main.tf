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
  subscription_id = "911e746f-0030-41d8-839c-c3579ec74ee4"
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = "West Europe"

  tags = {
    Environment = upper(var.environment)
    CreatedOn   = formatdate("YYYY-MM-DD", timestamp())
  }
}

