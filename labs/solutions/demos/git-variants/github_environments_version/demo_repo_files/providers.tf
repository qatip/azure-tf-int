terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  backend "azurerm" {} # backend settings are provided by the workflow via -backend-config
}

provider "azurerm" {
  features {}
  # keep sensitive input outside Git; provided by TF_VAR_subscription_id in the workflow
  subscription_id = var.subscription_id
}
