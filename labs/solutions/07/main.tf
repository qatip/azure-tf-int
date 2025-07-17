### Task1 ###
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.16.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "316f0ed4-2796-4561-a734-24b156826ae5"
}

resource "azurerm_resource_group" "RG_1" {
  name     = "RG1"
  location = "East US"
}


### Task2 ###

resource "azurerm_storage_account" "storage_acct_1" {
  name                     = "storageacctmichaelcg123"
  resource_group_name      = azurerm_resource_group.RG_1.name
  location                 = azurerm_resource_group.RG_1.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "storage_cont_1" {
  name                  = "example-container"
  storage_account_id    = azurerm_storage_account.storage_acct_1.id
  container_access_type = "private"
}


### Task3 ###
locals {
  mime_types = jsondecode(file("${path.module}/mime.json"))
}

resource "azurerm_storage_blob" "upload_files" {
  for_each = fileset("${path.module}/static_files", "**/*")
  name                   = each.key
  storage_account_name   = azurerm_storage_account.storage_acct_1.name
  storage_container_name = azurerm_storage_container.storage_cont_1.name
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

resource "azurerm_storage_management_policy" "storage_policy_1" {
  storage_account_id = azurerm_storage_account.storage_acct_1.id

  rule {
    name    = "blob-rule-1"
    enabled = true
    filters {
      blob_types   = ["blockBlob"]
    }
    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than    = 11
        tier_to_archive_after_days_since_modification_greater_than = 51
        delete_after_days_since_modification_greater_than          = 101
      }
      snapshot {
        delete_after_days_since_creation_greater_than = 30
      }
    }
  }
}


### Task5 ###

data "azurerm_storage_account_sas" "sas_1" {
  connection_string = azurerm_storage_account.storage_acct_1.primary_connection_string
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

  start  = "2025-01-01T00:00:00Z"
  expiry = "2026-01-01T00:00:00Z"

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
  value = data.azurerm_storage_account_sas.sas_1.sas
  sensitive = true
}