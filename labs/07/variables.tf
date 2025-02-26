variable "environment" {
  description = "Deployment environment (dev, test, prod)."
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project."
  type        = string
  default     = "TerraformProject"
}

variable "location" {
  description = "Azure region for resource deployment."
  type        = string
  default     = "East US"
}

variable "additional_tags" {
  description = "Additional tags to apply to resources."
  type        = map(string)
  default     = {
    Owner = "TeamA"
    CostCenter = "12345"
  }
}
