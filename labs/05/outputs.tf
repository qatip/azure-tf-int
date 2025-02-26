output "resource_group_name" {
  description = "The name of the created resource group"
  value       = azurerm_resource_group.example.name
}

output "storage_account_name" {
  description = "The name of the created storage account"
  value       = azurerm_storage_account.example.name
}

output "storage_account_replication" {
  description = "The replication type of the storage account"
  value       = azurerm_storage_account.example.account_replication_type
}

output "virtual_network_name" {
  description = "The name of the created virtual network"
  value       = azurerm_virtual_network.example.name
}

output "subnet_name" {
  description = "The name of the created subnet"
  value       = azurerm_subnet.example.name
}

output "route_table_name" {
  description = "The name of the created route table"
  value       = azurerm_route_table.example.name
}

output "security_group_name" {
  description = "The name of the created network security group"
  value       = azurerm_network_security_group.example.name
}

output "vm_name" {
  description = "The name of the created virtual machine"
  value       = azurerm_windows_virtual_machine.example.name
}

output "vm_public_ip" {
  description = "The public IP address of the virtual machine"
  value       = azurerm_public_ip.example.ip_address
}

output "admin_username" {
  description = "The administrator username for the virtual machine"
  value       = azurerm_windows_virtual_machine.example.admin_username
  sensitive   = true
}

output "nic_name" {
  description = "The name of the network interface associated with the VM"
  value       = azurerm_network_interface.example.name
}
