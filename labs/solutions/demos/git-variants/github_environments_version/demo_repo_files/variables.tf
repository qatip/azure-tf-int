variable "subscription_id" {
  type      = string
  sensitive = true
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "rg_name" {
  type    = string
  default = "rg-demo"
}

variable "environment" {
  type = string
}

variable "common_tags" {
  type    = map(string)
  default = {}
}
