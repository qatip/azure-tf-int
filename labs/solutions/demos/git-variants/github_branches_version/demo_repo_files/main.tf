terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

terraform {
  backend "azurerm" {}
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.name_prefix}-rg-${var.env}"
  location = var.location
  tags = {
    environment = var.env
    managed_by  = "github-actions"
  }
}
