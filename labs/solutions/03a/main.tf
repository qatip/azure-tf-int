provider "azurerm" {
  subscription_id = "<your subscription id>"
  features {}
}

resource "azurerm_resource_group" "lab_rg" {
  name     = "RG1"
  location = "West Europe"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "lab-vnet"
  location            = azurerm_resource_group.lab_rg.location
  resource_group_name = azurerm_resource_group.lab_rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "lab-subnet"
  resource_group_name  = azurerm_resource_group.lab_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "nic" {
  name                = "lab-nic"
  location            = azurerm_resource_group.lab_rg.location
  resource_group_name = azurerm_resource_group.lab_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "VM1"
  location            = azurerm_resource_group.lab_rg.location
  resource_group_name = azurerm_resource_group.lab_rg.name
  size                = var.vm_size
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  admin_password = "P@ssw0rd1234!"
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

}

# Local block to simulate logic error
locals {
  actual_storage_name = replace(var.storage_account_name, "lab", "lab")
}

resource "azurerm_storage_account" "storage" {
  name                     = local.actual_storage_name
  resource_group_name      = azurerm_resource_group.lab_rg.name
  location                 = azurerm_resource_group.lab_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  lifecycle {
    precondition {
      condition     = can(regex("^lab", var.storage_account_name))
      error_message = "Input name must start with 'lab'."
    }

    postcondition {
      condition     = can(regex("^lab", self.name))
      error_message = "Evaluated storage name does not start with 'lab'."
    }
  }
}
