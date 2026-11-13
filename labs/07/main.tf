# Copyright (c) 2026 QA Michael Coulling-Green. All rights reserved.

### Task 1 ###

# Add the complete Task 1 code from the lab instructions here.

### Task 2 ###

# Add the complete Task 2 code from the lab instructions here.

### Task 3 ###

# Uncomment this complete section when you reach Task 3.
# locals {
#   mime_types = jsondecode(file("${path.module}/mime.json"))
# }
#
# resource "azurerm_storage_blob" "upload_files" {
#   for_each = fileset("${path.module}/static_files", "**/*")
#
#   name                   = each.key
#   storage_account_name   = azurerm_storage_account.example.name
#   storage_container_name = azurerm_storage_container.example.name
#   type                   = "Block"
#   source                 = abspath("${path.module}/static_files/${each.key}")
#   content_md5            = filemd5("${path.module}/static_files/${each.key}")
#   content_type = lookup(
#     local.mime_types,
#     try(lower(regex("\\.[^.]+$", basename(each.key))), ""),
#     "application/octet-stream"
#   )
# }
#
# output "uploaded_blob_names" {
#   description = "Blob names managed by Terraform."
#   value       = sort(keys(azurerm_storage_blob.upload_files))
# }

### Task 4 ###

# Add the complete Task 4 code from the lab instructions here.

### Task 5 ###

# Add the complete Task 5 code from the lab instructions here.

