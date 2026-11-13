output "state_resource_group_name" {
  value       = azurerm_resource_group.state_rg.name
  description = "Resource group containing the Terraform state storage account."
}

output "state_storage_account_name" {
  value       = azurerm_storage_account.state.name
  description = "Storage account used for Terraform state."
}

output "state_container_name" {
  value       = azurerm_storage_container.state.name
  description = "Container used for Terraform state."
}

