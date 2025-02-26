terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.16.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "<your subscription id>"
}


resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "example" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = var.replication_type

  lifecycle {
    precondition {
      condition     = startswith(var.storage_account_name, "stg")
      error_message = "Storage account name must start with 'stg'."
    }
    postcondition {
      condition     = var.replication_type == "LRS"
      error_message = "Storage account replication type is incorrect. Expected 'LRS'."
    }
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "lab-vnet"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "lab-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.1.1.0/24"]

}

resource "azurerm_route_table" "example" {
  name                          = "lab-route-table"
  location                      = azurerm_resource_group.example.location
  resource_group_name           = azurerm_resource_group.example.name

  route {
    name           = "routelocal"
    address_prefix = "10.1.0.0/16"
    next_hop_type  = "VnetLocal"
  }

  route { 
    name = "routeinternet"
    address_prefix = "0.0.0.0/0"
    next_hop_type = "Internet"
  }
}

resource "azurerm_subnet_route_table_association" "example" {
  subnet_id      = azurerm_subnet.example.id
  route_table_id = azurerm_route_table.example.id

  depends_on = [azurerm_route_table.example]
}

resource "azurerm_network_security_group" "example" {
  name                = "lab_SecurityGroup"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "WebAdminNSG"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges     = [3389]
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.example.id
  network_security_group_id = azurerm_network_security_group.example.id

  depends_on = [azurerm_network_security_group.example]
}

resource "azurerm_network_interface" "example" {
  name                = "lab-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "lab_ip"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example.id
  }
}

resource "azurerm_windows_virtual_machine" "example" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_B2S"
  admin_username      = "TFadminuser"
  admin_password      = "TFP@$$w0rd1234!"
  network_interface_ids = [azurerm_network_interface.example.id,]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_public_ip" "example" {
  name                    = "lab-pip"
  location                = azurerm_resource_group.example.location
  resource_group_name     = azurerm_resource_group.example.name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
}

