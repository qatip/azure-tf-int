terraform {

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.16.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "911e746f-0030-41d8-839c-c3579ec74ee4"
}


/*
# Create Resource Groups dynamically using count
resource "azurerm_resource_group" "example1" {
  count    = var.resource_group_count
  name     = "rg-demo-${count.index}"
  location = var.location
}

output "resource_groups_example_1" {
  description = "Resource group names with their locations"
  value = [
    for rg in azurerm_resource_group.example1 : 
    "${rg.name} is in ${rg.location}"
  ]
}
*/


/*
# Resource groups created using for_each from lists with index-based keys"
resource "azurerm_resource_group" "example2" {
  for_each = {
    for index, name in var.rg-names : index => {
      name     = name
      location = var.locations[index]
    }
  }
  name     = each.value.name
  location = each.value.location
}

output "resource_groups_example_2" {
  description = "Resource groups created using for_each from lists with index-based keys"
  value = {
    for index_key, rg in azurerm_resource_group.example2 :
    index_key => {
      name     = rg.name
      location = rg.location
    }
  }
}
*/

#/*
# Create multiple Resource Groups using for_each
resource "azurerm_resource_group" "example3" {
  for_each = var.resource_groups
  name     = each.key
  location = each.value
}

# Outputs
output "resource_groups_example_3" {
  description = "Resource groups created with their locations"
  value = { for rg_name, rg in azurerm_resource_group.example3 :
    rg_name => rg.location
  }
}
#*/
