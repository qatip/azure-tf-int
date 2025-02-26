variable "vnets" {
  type = map(object({
    name          = string
    address_space = list(string) # list for possibility of multiple ranges
    location      = string
  }))
  default = {
    vnet1 = { name = "vnet-01", address_space = ["10.0.0.0/16"], location = "East US" }
    vnet2 = { name = "vnet-02", address_space = ["10.1.0.0/16"], location = "West Europe" }
  }
}

variable "subnets" {
  type = map(map(string)) 
  default = {
    "vnet1" = {
      "subnet-01" = "10.0.1.0/24"
      "subnet-02" = "10.0.2.0/24"
    }
    "vnet2" = {
      "subnet-03" = "10.1.1.0/24"
      "subnet-04" = "10.1.2.0/24"
    }
  }
}



