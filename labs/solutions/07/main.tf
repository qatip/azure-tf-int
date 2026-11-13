# Copyright (c) 2026 QA Michael Coulling-Green. All rights reserved.

### Task 1 ###

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

locals {
  tags = merge({
    Environment = "Training"
    Project     = "TerraformStorage"
    Lab         = "07"
  }, var.additional_tags)
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

output "resource_group_name" {
  description = "Dedicated resource group created for this lab."
  value       = azurerm_resource_group.example.name
}

### Task 2 ###

resource "azurerm_storage_account" "example" {
  name                            = var.storage_account_name
  resource_group_name             = azurerm_resource_group.example.name
  location                        = azurerm_resource_group.example.location
  account_kind                    = "StorageV2"
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  access_tier                     = "Hot"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  shared_access_key_enabled       = true
  allow_nested_items_to_be_public = false
  tags                            = local.tags
}

resource "azurerm_storage_container" "example" {
  name                  = "example-container"
  storage_account_id    = azurerm_storage_account.example.id
  container_access_type = "private"
}

output "storage_account_name" {
  description = "Globally unique storage account name."
  value       = azurerm_storage_account.example.name
}

output "container_name" {
  description = "Private container used by this lab."
  value       = azurerm_storage_container.example.name
}

output "container_url" {
  description = "Container address without a SAS; this does not grant access."
  value       = "${azurerm_storage_account.example.primary_blob_endpoint}${azurerm_storage_container.example.name}"
}

### Task 3 ###

locals {
  mime_types = jsondecode(file("${path.module}/mime.json"))
}

resource "azurerm_storage_blob" "upload_files" {
  for_each = fileset("${path.module}/static_files", "**/*")

  name                   = each.key
  storage_account_name   = azurerm_storage_account.example.name
  storage_container_name = azurerm_storage_container.example.name
  type                   = "Block"
  source                 = abspath("${path.module}/static_files/${each.key}")
  content_md5            = filemd5("${path.module}/static_files/${each.key}")
  content_type = lookup(
    local.mime_types,
    try(lower(regex("\\.[^.]+$", basename(each.key))), ""),
    "application/octet-stream"
  )
}

output "uploaded_blob_names" {
  description = "Blob names managed by Terraform."
  value       = sort(keys(azurerm_storage_blob.upload_files))
}

### Task 4 ###

resource "azurerm_storage_management_policy" "example" {
  storage_account_id = azurerm_storage_account.example.id

  rule {
    name    = "training-blob-lifecycle"
    enabled = true

    filters {
      blob_types = ["blockBlob"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than = 30
        delete_after_days_since_modification_greater_than       = 365
      }
    }
  }
}

### Task 5 ###

locals {
  sas_expiry_utc = timeadd(var.sas_start_utc, "8h15m")
}

data "azurerm_storage_account_sas" "example" {
  connection_string = azurerm_storage_account.example.primary_connection_string
  https_only        = true

  resource_types {
    service   = false
    container = true
    object    = true
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  start  = var.sas_start_utc
  expiry = local.sas_expiry_utc

  permissions {
    read    = true
    write   = false
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

locals {
  sas_query     = trimprefix(data.azurerm_storage_account_sas.example.sas, "?")
  blob_base_url = "${azurerm_storage_account.example.primary_blob_endpoint}${azurerm_storage_container.example.name}"
}

output "sas_expiry_utc" {
  description = "SAS expiry in UTC; renew the configured start time when necessary."
  value       = local.sas_expiry_utc
}

output "sas_url_query_string" {
  description = "Account SAS query string, including any provider-generated leading question mark."
  value       = data.azurerm_storage_account_sas.example.sas
  sensitive   = true
}

output "container_list_url" {
  description = "Sensitive URL that lists blobs in the lab container."
  value       = "${local.blob_base_url}?restype=container&comp=list&${local.sas_query}"
  sensitive   = true
}

output "teide_image_url" {
  description = "Sensitive URL that opens the supplied Teide.jpeg image."
  value       = "${local.blob_base_url}/Teide.jpeg?${local.sas_query}"
  sensitive   = true
}
