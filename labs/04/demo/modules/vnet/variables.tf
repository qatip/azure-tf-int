variable "resource_group_name" {}
variable "vnet_name" {}
variable "address_space" {
  type = list(string)
}
variable "location" {}

variable "subnets" {
  type = list(object({
    name           = string
    address_prefix = string
  }))
  default = []
}
