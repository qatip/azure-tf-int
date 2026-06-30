vnets = {
  vnet1 = {
    name          = "vnet-01"
    address_space = ["10.0.0.0/16"]
    location      = "East US"
  }

  vnet2 = {
    name          = "vnet-02"
    address_space = ["10.1.0.0/16"]
    location      = "West Europe"
  }
}

subnets = {
  vnet1 = {
    apps = "10.0.1.0/24"
    data = "10.0.2.0/24"
  }

  vnet2 = {
    apps = "10.1.1.0/24"
    data = "10.1.2.0/24"
  }
}