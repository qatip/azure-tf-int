variable "resource_group_name" {
  default = "demo-rg"
}

variable "location" {
  default = "West Europe"
}

variable "vm_name" {
  default = "demo-vm"
}

variable "admin_username" {
  default = "azureuser"
}

variable "name" {
  description = "Name to use in the template"
  default     = "world"
}
