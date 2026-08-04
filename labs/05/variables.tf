variable "vm_size" {
  type    = string


### Run the following command to verify the SKUs available in a given region (update as needed)
### Update the condition below to match
### az vm list-skus --location "UK West" --resource-type virtualMachines --output table


  validation {
    condition = contains([
      "Standard_D2s_V3",
      "Standard_B2s",
      "Standard_DS3_v2"
    ], var.vm_size)
    error_message = "Only the following VM sizes are allowed in this lab: Standard_D2s_V3, Standard_B2s or Standard_DS3_v2."
  }
}


variable "storage_account_name" {
  type    = string

  validation {
    condition     = can(regex("^lab", var.storage_account_name))
    error_message = "Storage account name must start with 'lab'."
  }
}
