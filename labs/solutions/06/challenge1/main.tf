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
  subscription_id = "<sub id>"
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = "West Europe"

  tags = {
    Environment = upper(var.environment)
    CreatedOn   = formatdate("YYYY-MM-DD", timestamp())
  }
}

