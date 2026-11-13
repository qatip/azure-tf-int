# Copyright (c) 2026 QA Michael Coulling-Green. All rights reserved.

variable "subscription_id" {
  description = "Azure subscription selected with Azure CLI when configuring this lab."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "subscription_id must be a subscription GUID."
  }
}

variable "resource_group_name" {
  description = "Dedicated resource group for this lab; do not use a group from another exercise."
  type        = string
  default     = "rg-tf-lab07"
}

variable "location" {
  description = "Azure region allowed by the training subscription."
  type        = string
  default     = "denmarkeast"
}

variable "storage_account_name" {
  description = "Globally unique storage account name: 3-24 lowercase letters and digits."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Use 3-24 lowercase letters and digits only."
  }
}

variable "sas_start_utc" {
  description = "Fixed SAS start in UTC, normally generated 15 minutes before the configuration time."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$", var.sas_start_utc)) && can(formatdate("YYYY-MM-DD", var.sas_start_utc))
    error_message = "Use a valid UTC timestamp such as 2026-11-12T09:00:00Z."
  }
}

variable "additional_tags" {
  description = "Additional or required course tags; values override the default lab tags."
  type        = map(string)
  default     = {}
}
