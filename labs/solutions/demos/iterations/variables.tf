variable "resource_group_count" {
  description = "The number of Resource Groups to create"
  type        = number
  default     = 2
}

variable "location" {
  description = "The Azure region"
  type        = string
  default     = "East US"
}

variable "rg-names" {
  description = "RG Names"
  type        = list(string)
  default     = ["rg-test", "rg-prod"]
  # default = ["rg-dev","rg-test","rg-prod"]

}

variable "locations" {
  description = "Locations"
  type        = list(string)
  default     = ["West Europe", "North Europe"]
  #  default = ["East US","West Europe","North Europe"]
}



variable "resource_groups" {
  description = "Map of resource group names to their locations"
  type        = map(string)
  default = {
    # "rg-east" = "East US"
    "rg-west"    = "West Europe"
    "rg-central" = "Central US"
  }
}

