### Task1 ###
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.74.0"
    }
  }
}

provider "azurerm" {
    features {}
    subscription_id = "{subscription id}" 
  # Configuration options
}

resource "azurerm_resource_group" "example" {
  name     = "RG1"
  location = "East US"
}


### Task2 ###
resource "azurerm_storage_account" "example" {
  name                     = "storageaccount{unique-suffix}"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "example" {
  name                  = "examplecontainer"
  storage_account_id    = azurerm_storage_account.example.id
  container_access_type = "private"
}

### Task3 ###
locals {
  mime_types = jsondecode(file("${path.module}/mime.json"))
}

resource "azurerm_storage_blob" "upload_files" {
  for_each = fileset("${path.module}/static_files", "**/*")
  name                   = each.key
  storage_account_name   = azurerm_storage_account.example.name
  storage_container_name = azurerm_storage_container.example.name
  type                   = "Block"
  source                 = "${path.module}/static_files/${each.key}"
  content_md5            = filemd5("${path.module}/static_files/${each.key}")
  
  content_type = lookup(
    local.mime_types,
    regex("\\.[^.]+$", each.key),
    "application/octet-stream"
  )
}

### Task4 ###
resource "azurerm_storage_management_policy" "example" {
  storage_account_id = azurerm_storage_account.example.id

  rule {
    name    = "rule1"
    enabled = true
    filters {
      blob_types   = ["blockBlob"]
    }
    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than    = 10
        tier_to_archive_after_days_since_modification_greater_than = 50
        delete_after_days_since_modification_greater_than          = 100
      }
    }
  }

}
### Task5 ###
data "azurerm_storage_account_sas" "example" {
  connection_string = azurerm_storage_account.example.primary_connection_string
  https_only        = true

  resource_types {
    service   = false
    container = true
    object    = false
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  start  = "2026-01-01T00:00:00Z"
  expiry = "2027-01-01T00:00:00Z"

  permissions {
    read    = true
    write   = true
    delete  = false
    list    = true
    add     = false
    create  = false
    update  = false
    process = false
    tag     = false
    filter  = false
  }
}

output "sas_url_query_string" {
  value = data.azurerm_storage_account_sas.example.sas
  sensitive = true
}