### Subscription and Resource Group ###
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.18.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "<sub id>"
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "RG1"
  location = "West Europe"
}

### Step 1: Vnet and Subnet ###
resource "azurerm_virtual_network" "example" {
  name                = "vnet-sql"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "example" {
  name                 = "subnet-sql"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

### Step 2: Public IP and Network Interface ###
resource "azurerm_public_ip" "example" {
  name                = "sql-public-ip"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "example" {
  name                = "sql-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example.id
  }

    depends_on = [azurerm_subnet.example,azurerm_public_ip.example]
}


### Step 3: Virtual Machine ###
resource "azurerm_windows_virtual_machine" "example" {
  name                  = "VM1"
  resource_group_name   = azurerm_resource_group.example.name
  location              = azurerm_resource_group.example.location
  size                  = "Standard_B2s"
  admin_username        = "adminuser"
  admin_password        = "YourSecurePassword123!"
  network_interface_ids = [azurerm_network_interface.example.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 128
  }

  source_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = "sql2022-ws2022"
    sku       = "standard-gen2"
    version   = "latest"
  }

  depends_on = [azurerm_network_interface.example,azurerm_network_interface_security_group_association.example]

}


### Step 4: Security Rules ###
resource "azurerm_network_security_group" "example" {
  name                = "sql-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_network_security_rule" "allow_rdp" {
  name                        = "allow-rdp"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name

  depends_on = [azurerm_network_security_group.example]
}

resource "azurerm_network_security_rule" "allow_sql" {
  name                        = "allow-sql"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "1433"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name

  depends_on = [azurerm_network_security_group.example]
}

resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.example.id
  network_security_group_id = azurerm_network_security_group.example.id

  depends_on = [azurerm_network_security_rule.allow_rdp,azurerm_network_security_rule.allow_sql]
}

### Step 5: Output the Public IP Address ###
output "vm_public_ip" {
  value = azurerm_public_ip.example.ip_address
}


