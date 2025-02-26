variable "resource_group_name" {
  description = "Name of the resource group (must be RG1 to RG6)"
  type        = string
  default     = "RG1"

  validation {
    condition     = can(regex("^RG[1-6]$", var.resource_group_name))
    error_message = "Resource group name must be one of: RG1, RG2, RG3, RG4, RG5, or RG6."
  }
}

variable "environment" {
  description = "Environment type (must be DEV, PROD, or TEST)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["DEV", "PROD", "TEST"], upper(var.environment))
    error_message = "Environment must be one of: DEV, PROD, or TEST."
  }
}
