# QATIPINT — Azure Lab 07

## Managing Azure Blob Storage using Terraform

**Version:** 2.0.2
**Date:** 12 November 2026  
**Author:** Michael Coulling-Green — mcgreen@qa.com

## Contents

- [Lab objectives](#lab-objectives)
- [What you will build](#what-you-will-build)
- [Before you begin](#before-you-begin)
- [Task 1. Create the resource group](#task-1-create-the-resource-group)
- [Task 2. Create the storage account and private container](#task-2-create-the-storage-account-and-private-container)
- [Task 3. Upload the supplied files](#task-3-upload-the-supplied-files)
- [Task 4. Add a lifecycle management policy](#task-4-add-a-lifecycle-management-policy)
- [Task 5. Generate a shared access signature](#task-5-generate-a-shared-access-signature)
- [Task 6. Test access using the SAS](#task-6-test-access-using-the-sas)
- [Task 7. Clean up](#task-7-clean-up)
- [Troubleshooting](#troubleshooting)
- [Reference documentation](#reference-documentation)

## Lab objectives

By the end of this lab you will be able to:

- Create an Azure resource group, storage account and private blob container.
- Use Terraform references to express dependencies between resources.
- Use `fileset()` and `for_each` to upload multiple files.
- Assign MIME content types and detect changes in local file content.
- Define a lifecycle management policy for block blobs.
- Generate an HTTPS-only, time-limited SAS with read and list permissions.
- Explain the difference between sensitive output redaction and state protection.
- Use the SAS to list blobs and display an image without making the container public.

## What you will build

| Component | Lab configuration |
| --- | --- |
| Resource group | Dedicated group, default `rg-tf-lab07` |
| Storage account | Standard StorageV2, LRS, Hot default tier |
| Region | `denmarkeast`, unless your instructor specifies another allowed region |
| Container | `example-container`, private |
| Files | `ipsum.txt`, `laptop.png`, `Teide.jpeg` |
| Lifecycle | Cool after 30 days; delete after 365 days since last modification |
| SAS | Blob service; container and object resource types; read and list; HTTPS only |
| SAS lifetime | Expires approximately eight hours after lab settings are generated or renewed |

This is a Terraform storage lab. The browser accesses Azure Storage directly using the SAS. There is no application or web server to deploy.

The code is deliberately pinned to **AzureRM 4.16.0**, matching the original lab. Use the versioned references at the end rather than copying examples from the latest provider documentation, which may use different arguments.

## Before you begin

### 1. Check prerequisites

Complete Lab 0. You need Windows, VS Code, PowerShell 7 or later, Terraform 1.5 or later (below 2.0), Azure CLI, internet access to the Terraform providers and Azure endpoints, and your assigned Azure subscription.

Your account needs permission to create resources and retrieve storage account keys. Subscription-level Contributor is sufficient for these operations, subject to Azure Policy and any training restrictions. The subscription must allow Shared Key access for this SAS exercise. The storage public endpoint must be reachable from your workstation; the container itself remains private.

### 2. Review the files in the course folders

Open the course folder in VS Code. In its terminal, run:

```powershell
Set-Location C:\azure-tf-int\labs\07
Get-ChildItem
Get-ChildItem .\static_files
```

| Path | Purpose |
| --- | --- |
| `C:\azure-tf-int\labs\07` | Guided student exercise |
| `C:\azure-tf-int\labs\solutions\07` | Complete configuration for reference or instructor testing |
| `main.tf` | Task sections; Task 3 upload code is supplied commented out in the starter |
| `versions.tf` | Terraform and AzureRM version constraints |
| `variables.tf` | Inputs used by the lab |
| `Configure-Lab.ps1` | Creates local input values or renews the SAS time window |
| `mime.json` | File-extension-to-content-type mappings |
| `static_files` | Three original sample files |

The sample files should be `ipsum.txt`, `laptop.png` and **`Teide.jpeg`**. Blob names are case-sensitive.

### 3. Authenticate and check the subscription

```powershell
az login
az account show --query '{Subscription:name,SubscriptionId:id,TenantId:tenantId}' --output table
```

If the wrong subscription is selected, replace the placeholder and run:

```powershell
az account set --subscription "<your training subscription ID>"
az account show --query '{Subscription:name,SubscriptionId:id,TenantId:tenantId}' --output table
```

Do not proceed until this shows your assigned training subscription.

### 4. Generate the lab settings

```powershell
Unblock-File -LiteralPath "C:\azure-tf-int\labs\07\Configure-Lab.ps1"
.\Configure-Lab.ps1
Get-Content .\terraform.tfvars.json
```

The script reads your current Azure CLI subscription, generates a valid storage account name beginning with `storageacct`, and writes `terraform.tfvars.json`. It does not deploy anything or change your Azure CLI subscription.

Check the subscription ID, region, resource group and tags. The provider uses the subscription ID in this file, so switching Azure CLI subscriptions later does not update this lab's target automatically.

Storage account names must be globally unique and contain 3–24 lowercase letters and digits. The random suffix reduces the chance of a collision. You can specify your own valid name, region or tags when first creating settings, for example:

```powershell
.\Configure-Lab.ps1 -Location denmarkeast -StorageAccountName storageacctmcg0712 -AdditionalTags @{ CostCenter = 'Training' }
```

Run either the default command or the customised command, once. The script refuses to overwrite an existing settings file. To change existing values, edit `terraform.tfvars.json` and review the next plan. To renew only the SAS window, use `-RenewSas`, as described in Task 5.

The settings also contain `sas_start_utc`, set 15 minutes before the current UTC time to allow for clock differences. Task 5 derives the expiry from this fixed input. Keeping it in a file avoids changing the token on every plan.


### Working through the tasks

For each task, try the requirements first and then use the guided code if needed. Keep `versions.tf`, `variables.tf`, `mime.json` and the generated settings file in place.

Add code to the matching task section in `main.tf`. Do not paste an entire file over earlier completed tasks. Terraform reads all `.tf` files in the current directory together; do not copy the solution into a subdirectory expecting it to join the starter configuration.

After each change run the format, validate, plan and apply commands shown. Type `yes` only after checking the resources and subscription. An ordinary `terraform apply` makes a fresh plan; the separate plan step is for review.

The completed solution is in `C:\azure-tf-int\labs\solutions\07`. Use it as a reference. The instructor test procedure in `README_Testing.md` explains how to run it independently.

## Task 1. Create the resource group

### Try it yourself

Configure the AzureRM provider with an empty `features {}` block and the subscription ID input. Merge default training tags with `additional_tags`, then create a dedicated resource group using the name and location inputs. Add an output for its name.

### Guided steps

1. Open `versions.tf` and identify the exact AzureRM provider constraint.
2. Open `variables.tf` and identify the inputs that Task 1 uses.
3. Add the following to the **Task 1** section of `main.tf`:

```hcl
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
```

`features {}` is required by AzureRM and accepts the default resource-specific provider behaviour. The provider's `subscription_id` comes from your local settings; no client secret is needed for this interactive Azure CLI login.

`merge()` combines the default tags with `additional_tags`. Values in the second map override matching keys in the first map.

4. Save and run:

```powershell
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

5. Verify the dedicated resource group in the Azure Portal.

**Checkpoint:** one resource group is managed in this working directory's state. The `resource_group_name` output shows its name.

## Task 2. Create the storage account and private container

### Try it yourself

Create a Standard StorageV2 account using LRS and a Hot default tier. Use your input account name and reference the resource group's name and location. Require HTTPS and TLS 1.2, allow Shared Key access for the later SAS task, and prevent anonymous blob access. Create a private container named `example-container`.

### Guided steps

1. Add the following to the **Task 2** section of `main.tf`:

```hcl
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
```

The account's references to `azurerm_resource_group.example` create an implicit dependency. The container's `storage_account_id` reference creates another dependency. Terraform therefore creates the group before the account, and the account before the container. No explicit `depends_on` is needed for these references. An implicit dependency orders operations; it does not guarantee that every Azure API immediately reflects a newly created resource.

`container_access_type = "private"` means anonymous requests cannot read the blobs. Public network reachability and anonymous data access are separate settings: your workstation must reach the endpoint, while requests still need authorisation.

The `container_url` output contains no credential. Knowing the address does not grant access.

2. Save and run:

```powershell
terraform fmt
terraform validate
terraform plan
terraform apply
```

3. In the Azure Portal, inspect the account and its container. Confirm the account is Standard/LRS and the container is private. The container is empty at this stage.

**Checkpoint:** the group, storage account and private container exist. No container has been made public.

## Task 3. Upload the supplied files

### Try it yourself

Review and enable the supplied Task 3 code. Explain how it identifies files, creates one resource per file, assigns blob names and content types, and detects content changes.

### Guided steps

1. In the **Task 3** section of the starter `main.tf`, remove the comment markers from the complete Terraform code, including its output. Leave the section heading and explanatory comment as comments. Alternatively, replace that commented section with the code below. Do not keep two active copies.

```hcl
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
```

2. Examine the expressions:

| Expression | Purpose |
| --- | --- |
| `path.module` | Directory containing this Terraform module |
| `jsondecode(file(...))` | Loads `mime.json` as a map |
| `fileset(..., "**/*")` | Finds files recursively beneath `static_files` |
| `for_each` | Creates one blob resource instance per relative file path |
| `each.key` | Relative file path used as both the resource key and blob name |
| `source` with `abspath()` | Absolute path of the local file uploaded to Azure |
| `filemd5()` | Computes a hash of local file content; changed content changes this argument |
| `basename()` | Examines only the filename when extracting an extension |
| `regex("\\.[^.]+$", ...)` | Extracts the final extension, such as `.jpeg` |
| `lower()` | Normalises extensions such as `.PNG` to `.png` |
| `try(..., "")` | Uses an empty extension if there is no regex match |
| `lookup(..., "application/octet-stream")` | Uses a MIME mapping, or a binary default for unknown or missing extensions |

Because `for_each` uses file paths as keys, Terraform gives each file its own address, such as `azurerm_storage_blob.upload_files["Teide.jpeg"]`. Renaming or removing a local file changes which blob resources Terraform manages; review the plan before applying such changes.

The MD5 value is useful for content change detection. In this provider version, changing `content_md5` causes replacement of the blob resource. It is not an encryption or security mechanism.

3. Open `mime.json`. For the supplied files, expect:

| Blob | Content type |
| --- | --- |
| `ipsum.txt` | `text/plain` |
| `laptop.png` | `image/png` |
| `Teide.jpeg` | `image/jpeg` |

4. Save and run:

```powershell
terraform fmt
terraform validate
terraform plan
terraform apply
terraform output uploaded_blob_names
```

5. In the Azure Portal, open the container and check all three blobs. Inspect each blob's properties and confirm its content type. If the portal cannot display data because of your signed-in account's data permissions, use the SAS test in Task 6; management access and blob data access are different permissions.

**Checkpoint:** Terraform manages three blob resources, and `Teide.jpeg` has content type `image/jpeg`.

## Task 4. Add a lifecycle management policy

### Try it yourself

Create one enabled lifecycle rule for block blobs in this account. Apply it without a prefix or blob-index-tag filter. Use time since last modification to move blobs to Cool after 30 days and delete them after 365 days. Focus on current base blobs.

### Guided steps

1. Add the following to the **Task 4** section of `main.tf`:

```hcl
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
```

The rule applies to block blobs across the account, rather than only this container. Both conditions measure age since last modification; the deletion threshold is not an additional waiting period after the move to Cool.

| Age since last modification | Configured action |
| --- | --- |
| More than 30 days | Move to Cool |
| More than 365 days | Delete |

Cool is an online tier, so blobs remain readable after that transition. This lab verifies the policy definition. The simplified rule uses Cool and deletion only.

2. Save and run:

```powershell
terraform fmt
terraform validate
terraform plan
terraform apply
```

3. Open the account's **Lifecycle management** page in the Azure Portal. Inspect `training-blob-lifecycle` and its base-blob actions.

Newly uploaded files do not meet these age conditions. Azure processes lifecycle policies asynchronously, and changes can take up to 24 hours to begin executing. You are not expected to observe any tier changes or deletions during the class.

**Checkpoint:** one enabled lifecycle rule exists with the two specified thresholds.

## Task 5. Generate a shared access signature

### Try it yourself

Generate an account SAS for Blob Storage. Enable the container and object resource types, read and list permissions, and HTTPS only. Use the configured fixed UTC start time and derive the expiry. Add sensitive outputs for the token and the two complete browser URLs.

### Guided steps

1. Add the following complete code to the **Task 5** section of `main.tf`, including all locals and outputs:

```hcl
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
```

2. Review the authorisation settings:

| Setting | Reason |
| --- | --- |
| `service = false` | Service-level operations are outside the exercise |
| `container = true` | Enables the resource type needed to list blobs within a container |
| `object = true` | Enables the resource type needed to read an individual blob |
| `blob = true` | Limits the token to the Blob service |
| `read = true`, `list = true` | Matches the two requests you will test |
| All other permissions false | Upload, modification and deletion are not required |
| `https_only = true` | Rejects HTTP use of this token |

This is an **account SAS**, signed using the storage account key. It is not scoped to just `example-container` or `Teide.jpeg`: its permissions can apply to matching resources across the Blob service in this account. The URL selects the target of a request; it does not narrow the SAS itself.

The data source generates a signed token; it does not create a separately registered SAS resource in Azure. You will not find this particular generated token listed as an Azure resource in the portal.

For production designs, prefer Microsoft Entra authorisation where suitable. Where delegated SAS access is required, consider a user delegation SAS. This exercise intentionally demonstrates an account SAS; it is not an OIDC or user delegation SAS exercise.

### Understand the time window

`Configure-Lab.ps1` sets `sas_start_utc` 15 minutes before the time you run it. Adding `8h15m` gives an expiry approximately eight hours after that configuration step. This buffer helps with clock differences. The timestamp is UTC, independent of local time or daylight saving.

The start is a fixed input. Ordinary plans do not renew the token. If the lab spans more than eight hours, or you revisit it on another day, renew the window:

```powershell
.\Configure-Lab.ps1 -RenewSas
```

Then plan and apply as below. Renewal changes only `sas_start_utc` in the settings file. It does not rotate the account key or revoke earlier tokens, which remain usable until they expire while the account and signing key remain valid.

### Understand sensitive values

`sensitive = true` hides these outputs in ordinary plan and apply output. It does **not** encrypt the token, remove it from state, or make a token-bearing URL safe to share. Terraform state can also contain the storage keys and connection string. Treat local state, state backups and saved plans as sensitive.

3. Save and run:

```powershell
terraform fmt
terraform validate
terraform plan
terraform apply
terraform output sas_expiry_utc
```

The SAS outputs should appear as sensitive values in ordinary apply output. They are intentionally revealed only when you request them in Task 6.

**Checkpoint:** the SAS has a current UTC expiry, read/list permissions, and sensitive outputs.

## Task 6. Test access using the SAS

Use the outputs so you do not need to manually join query strings or edit encoded token characters. The code removes a leading `?` when present and adds each URL's separators in the correct place.

### 1. List the blobs

```powershell
$listUrl = terraform output -raw container_list_url
Start-Process $listUrl
```

The browser should show an XML listing containing `ipsum.txt`, `laptop.png` and `Teide.jpeg`. Some browsers show an XML formatting notice; the listing is still the expected result.

If browser launch is restricted, run the following and copy the entire URL into the browser address bar:

```powershell
terraform output -raw container_list_url
```

This explicitly prints a sensitive URL. Keep it out of shared screenshots and documents.

### 2. Display the Teide image

```powershell
$imageUrl = terraform output -raw teide_image_url
Start-Process $imageUrl
```

The browser should show the Teide photograph. The image URL uses the exact blob name **`Teide.jpeg`**, with no container-list query parameters.

The same SAS authorises two different requests: a container listing and a blob read. The assigned MIME type tells the browser that the second response is a JPEG image.

### 3. Verify the listing in PowerShell

```powershell
$response = Invoke-WebRequest -Uri $listUrl -Method Get
[xml]$listing = $response.Content.TrimStart([char]0xFEFF)
$listing.SelectNodes('/EnumerationResults/Blobs/Blob/Name') | Select-Object @{Name='Name';Expression={$_.InnerText}}
```

Expect all three names. This explicitly parses the response body as XML and selects the blob name elements, rather than relying on automatic conversion. `TrimStart()` removes a leading byte-order-mark character if present. This request uses only the URL's SAS for authorisation; it does not use your Azure CLI login.

If the table is still empty, inspect the returned listing:

```powershell
$listing.OuterXml
```

A valid listing with no `Blob` entries means the requested container returned no blobs. Check the target account and container against the Terraform outputs and confirm Task 3 was applied.

### 4. Confirm anonymous access is denied

```powershell
$anonymousImageUrl = (terraform output -raw container_url) + '/Teide.jpeg'
Start-Process $anonymousImageUrl
```

This fresh URL has no SAS query string. The image should not display; Azure Storage should return an access error. The precise error text can vary. The successful signed request did not make the container public.

### 5. Check Terraform has reached the intended state

```powershell
terraform plan
```

With unchanged settings and files, expect no changes. The fixed SAS input avoids a new token on every plan.

**Checkpoint:** the signed URL lists three blobs, the signed image URL displays the photo, anonymous image access fails, and the final plan reports no changes.

## Task 7. Clean up

1. Confirm you are still in the directory that owns the deployment and its state:

```powershell
Get-Location
terraform output resource_group_name
terraform state list
```

If you tested from `solutions`, clean up from that folder instead of the starter folder.

2. Review the destruction plan, then destroy the lab resources:

```powershell
terraform plan -destroy
terraform destroy
```

Type `yes` only after checking that the listed objects belong to this lab. This deletes the blobs and dedicated resource group as well as the account and container. Do not delete the group manually first: Terraform should carry out the cleanup using its state.

3. Confirm the dedicated group and account have gone from Azure. Close browser tabs containing SAS URLs and remove these temporary variables from your terminal:

```powershell
Remove-Variable listUrl,imageUrl,anonymousImageUrl,listing,response -ErrorAction SilentlyContinue
```

Deleting the storage account makes these URLs unusable against that account. Local settings and state backups may still contain sensitive information: keep them out of Git and dispose of them according to the course's workstation cleanup procedure.

**Checkpoint:** the lab resources have been destroyed using the correct working directory and state.

## Troubleshooting

| Symptom | Checks and next action |
| --- | --- |
| `Reference to undeclared resource` | All guided resource labels use `example`. Check for a renamed label or a missing task section. |
| `Duplicate ... configuration` | Keep one active copy of each task. Do not leave both an uncommented Task 3 and a second pasted copy. |
| Terraform prompts for an input | Check `terraform.tfvars.json` exists in the current working directory and contains all generated values. Run the configuration script in this lab folder if settings have not been created. |
| Wrong subscription in a plan or error | Inspect `subscription_id` in `terraform.tfvars.json` as well as `az account show`. The provider uses the file's subscription ID. Correct the file before applying. |
| Azure login has expired | Repeat the approved login command, verify the selected training subscription, then retry the plan. |
| Provider registration or permission error | Read the named provider in the error. `Microsoft.Storage` must be registered for storage resources. Ask the instructor to check subscription permissions and required registrations. Register only providers approved for the training subscription. |
| Storage account name is invalid or unavailable | Use 3–24 lowercase letters/digits and a globally unique name. Edit the local settings before deployment. Changing a deployed account name plans replacement, so review the plan. |
| Azure Policy rejects a region or tags | Use an instructor-approved region and required tags in the settings file. Changing the region after deployment can replace resources. |
| Resource group name already exists | Do not import or delete an unrelated group. Before creating this lab, choose a different dedicated name in the settings. If this is an earlier deployment, use its original working directory and state. |
| A just-created resource is temporarily reported missing | Confirm the subscription and references, then retry a fresh plan once Azure has settled. Resource references already establish ordering; an arbitrary extra `depends_on` does not fix service propagation. |
| Blob upload returns a 403 | Check the detailed Azure error, account-key permissions, Shared Key policy and network reachability. This lab requires permitted Shared Key access. Adding an Entra data role alone does not override a policy that disables Shared Key. |
| Portal cannot browse blobs | Portal data browsing can need separate data permissions. Use the SAS-based tests to verify this lab independently of the portal login. |
| `tierToArchive is not supported for the account` | Remove any Archive action retained from an earlier lab version. The current rule has only a Cool transition and deletion. Run a fresh plan and apply. |
| No lifecycle action occurs during class | Expected: the files are new and processing is asynchronous. Verify the saved rule definition. |
| SAS URL returns an authorisation or time error | Check `sas_expiry_utc`, the fixed start in settings, HTTPS and your device clock. Run `Configure-Lab.ps1 -RenewSas`, plan/apply, and retrieve new URLs. Check whether subscription policy restricts SAS duration or Shared Key. |
| Image is missing or downloads unexpectedly | Check `Teide.jpeg` exists with exactly that case and content type `image/jpeg`. Apply Task 3 and retrieve the current image URL. |
| A pasted URL fails | Retrieve the complete URL again. Do not decode `%` sequences, alter encoded characters, add spaces, or change `&` separators. |
| Sensitive-output error | Each token-bearing output must include `sensitive = true`. Copy the complete Task 5 block. |
| Destroy cannot find expected resources | Check your directory, subscription input and state. Do not delete state or copy another working directory's state as a workaround. |

## Reference documentation

- [AzureRM 4.16.0 provider](https://registry.terraform.io/providers/hashicorp/azurerm/4.16.0)
- [Storage account — AzureRM 4.16.0](https://registry.terraform.io/providers/hashicorp/azurerm/4.16.0/docs/resources/storage_account)
- [Storage container — AzureRM 4.16.0](https://registry.terraform.io/providers/hashicorp/azurerm/4.16.0/docs/resources/storage_container)
- [Storage blob — AzureRM 4.16.0](https://registry.terraform.io/providers/hashicorp/azurerm/4.16.0/docs/resources/storage_blob)
- [Storage management policy — AzureRM 4.16.0](https://registry.terraform.io/providers/hashicorp/azurerm/4.16.0/docs/resources/storage_management_policy)
- [Storage account SAS — AzureRM 4.16.0](https://registry.terraform.io/providers/hashicorp/azurerm/4.16.0/docs/data-sources/storage_account_sas)
- [Terraform sensitive data](https://developer.hashicorp.com/terraform/language/manage-sensitive-data)
- [Azure account SAS](https://learn.microsoft.com/en-us/rest/api/storageservices/create-account-sas)
- [Azure lifecycle management](https://learn.microsoft.com/en-us/azure/storage/blobs/lifecycle-management-overview)
- [Azure blob access tiers](https://learn.microsoft.com/en-us/azure/storage/blobs/access-tiers-overview)

## Copyright

© 2026 QA Michael Coulling-Green. All rights reserved. These lab materials are provided as part of an authorised training course. Course attendees may reuse these materials for their own personal learning and reference outside of the training session. Unauthorised copying, redistribution, publication, or use of these materials to deliver training is prohibited without prior written permission from the author.
