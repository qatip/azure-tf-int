variable "vm_size" {
  type    = string

  validation {
    condition = contains([
      "Standard_D2s_V3",
      "Standard_DS2_V2",
      "Standard_B2S",
      "Standard_DS3_v2"
    ], var.vm_size)
    error_message = "Only the following VM sizes are allowed in this lab: Standard_D2s_V3, Standard_DS2_V2, Standard_B2S, Standard_DS3_v2."
  }
}


variable "storage_account_name" {
  type    = string

  validation {
    condition     = can(regex("^lab", var.storage_account_name))
    error_message = "Storage account name must start with 'lab'."
  }
}