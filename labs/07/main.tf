### Task1 ###

### Task2 ###

### Task3 ###
#locals {
#  mime_types = jsondecode(file("${path.module}/mime.json"))
#}
#
#resource "azurerm_storage_blob" "upload_files" {
#  for_each = fileset("${path.module}/static_files", "**/*")
#  name                   = each.key
#  storage_account_name   = azurerm_storage_account.storage_acct_1.name
#  storage_container_name = azurerm_storage_container.storage_cont_1.name
#  type                   = "Block"
#  source                 = "${path.module}/static_files/${each.key}"
#  content_md5            = filemd5("${path.module}/static_files/${each.key}")
#  
#  content_type = lookup(
#    local.mime_types,
#    regex("\\.[^.]+$", each.key),
#    "application/octet-stream"
#  )
#}
#
### Task4 ###

### Task5 ###
