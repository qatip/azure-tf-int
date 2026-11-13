variable "subscription_id" {
  type = string
}

variable "location" {
  type        = string
  description = "Azure region for the Terraform state resources."
}

variable "project_name" {
  type        = string
  description = "Short project name used as a prefix for state resources."
}

variable "env" {
  type        = string
  description = "Environment indicator for shared state resources."
  default     = "shared"
}

variable "state_storage_account_name" {
  type        = string
  description = "Globally unique storage account name for Terraform state."
}

variable "state_container_name" {
  type        = string
  description = "Blob container name for Terraform state."
  default     = "tfstate"
}
