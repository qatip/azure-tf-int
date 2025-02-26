variable "resource_group_name" {
  type        = string
  validation {
    condition     = can(regex("^RG[1-6]$", var.resource_group_name))
    error_message = "Resource group name must be RG1 through RG6."
  }
}

variable "location" {
  type        = string
  validation {
    condition     = contains(["East US", "West Europe"], var.location)
    error_message = "Location must be either 'East US' or 'West Europe'."
  }
}

variable "storage_account_name" {
  type        = string
}

variable "vm_name" {
  type        = string
  validation {
    condition     = can(regex("^VM[1-6]$", var.vm_name))
    error_message = "VM name must be between VM1 and VM6."
  }
}

variable "replication_type" {
  description = "Replication type for the storage account."
  type        = string
  default     = "LRS" # Ensuring it defaults to LRS
  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RA-GZRS"], var.replication_type)
    error_message = "Invalid replication type. Must be one of LRS, GRS, RAGRS, ZRS, GZRS, or RA-GZRS."
  }
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  validation {
    condition     = contains(["Standard_B2s", "Standard_D2s_v3"], var.vm_size)
    error_message = "Invalid VM size. Allowed values: Standard_B2s, Standard_D2s_v3."
  }
}