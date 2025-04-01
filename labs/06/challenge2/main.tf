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

locals {
  # Load JSON file containing inconsistent VM names

  # Define regex patterns for stages and projects

  # Process and clean each VM name dynamically
    corrected_vm_names = {}
}

# Output the corrected VM names
output "corrected_vm_names" {
  value = local.corrected_vm_names
}
