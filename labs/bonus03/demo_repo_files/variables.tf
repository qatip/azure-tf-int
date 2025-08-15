variable "subscription_id" {
  description = "Azure subscription ID (supplied by CI/CD)"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "westeurope"
}

variable "env" {
  description = "Environment name (e.g., prod, dev)"
  type        = string
  default     = "prod"
}

variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "demo"
}
