output "vnet_details" {
  value = {
    id             = azurerm_virtual_network.vnet.id
    name           = azurerm_virtual_network.vnet.name
    location       = azurerm_virtual_network.vnet.location
    resource_group = azurerm_virtual_network.vnet.resource_group_name
  }
}

output "subnets" {
  value = { for s in azurerm_subnet.subnet : s.name => s.id }
}