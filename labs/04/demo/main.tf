terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.16.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "<your subscription id>"
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "RG1"
  location = "East US"
}

module "vnets" {
  for_each = var.vnets
  source              = "./modules/vnet"
  vnet_name           = each.value.name
  address_space       = each.value.address_space
  location            = each.value.location
  resource_group_name = azurerm_resource_group.example.name
  subnets             = [for k, v in var.subnets[each.key] : { name = k, address_prefix = v }]
}

#module "nsgs" {
#  for_each = { for k, v in module.vnets : k => v.vnet_details }
#  source              = "./modules/nsg"
#  nsg_name            = "${each.value.name}-nsg"
#  location            = each.value.location
#  resource_group_name = azurerm_resource_group.example.name
#}

#resource "azurerm_subnet_network_security_group_association" "nsg_association" {
#  for_each = merge([
#    for k, v in module.vnets : {for subnet_name, subnet_id in v.subnets : subnet_name => {
#      vnet  = k
#      id    = subnet_id
#      }
#    }
#  ]...)
#
#  subnet_id = each.value.id
#
#  network_security_group_id = module.nsgs[each.value.vnet].nsg_id
#  depends_on = [
#    module.vnets,
#    module.nsgs
#  ]
#}

#resource "azurerm_virtual_network_peering" "peerings" {
#  for_each = {
#    peer1to2 = { local = "vnet1", remote = "vnet2" }
#    peer2to1 = { local = "vnet2", remote = "vnet1" }
#  }
#
#  name                      = each.key
#  resource_group_name       = azurerm_resource_group.example.name
#  virtual_network_name      = module.vnets[each.value.local].vnet_details.name
#  remote_virtual_network_id = module.vnets[each.value.remote].vnet_details.id
#}


