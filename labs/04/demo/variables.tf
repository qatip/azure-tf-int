variable "vnets" {
  description = "Virtual networks to create"

  type = map(object({
    name          = string
    address_space = list(string)
    location      = string
  }))
}

variable "subnets" {
  description = "Subnets for each virtual network"

  type = map(map(string))
}