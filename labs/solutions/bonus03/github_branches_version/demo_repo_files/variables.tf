variable "subscription_id" {
  description = "Azure subscription ID (supplied by CI/CD or manually)"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "env" {
  description = "Environment name (e.g., prod, dev)"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

