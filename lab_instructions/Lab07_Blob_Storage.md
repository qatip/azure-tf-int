# QATIP Intermediate - Azure Lab 07

## Managing Azure Storage using Terraform

**Version:** 1.2.0 | **Date:** 08/11/26 | **Author:** mcgreen@qa.com

## Contents

- [Lab Objectives](#lab-objectives)
- [Teaching Points](#teaching-points)
- [Before you begin](#before-you-begin)
- [Solution](#solution)
- [Task 1. Create a resource group](#task-1-create-a-resource-group)
- [Task 2. Add a Blob Storage account and container](#task-2-add-a-blob-storage-account-and-container)
- [Task 3. Examine the file upload code](#task-3-examine-the-file-upload-code)
- [Task 4. Create an Azure Storage management policy](#task-4-create-an-azure-storage-management-policy)
- [Task 5. Create an Azure Storage access signature token](#task-5-create-an-azure-storage-access-signature-token)
- [Task 6. Using the SAS token](#task-6-using-the-sas-token)
- [Task 7. Lab clean-up](#task-7-lab-clean-up)

## Lab Objectives

In this lab, you will use Terraform to create the following:

- Resource group.
- Storage account.
- Container.
- Storage management policy.
- Shared access signature (SAS) token.

## Teaching Points

This lab focuses on using Terraform to create and manage Azure storage accounts, including creating containers, uploading data, configuring storage management policies, and generating SAS tokens.

## Before you begin

1. Ensure you have completed **Lab 0**.
2. In the IDE terminal pane, enter:

   ```powershell
   cd C:\azure-tf-int\labs\07
   ```

3. This changes your working directory to `C:\azure-tf-int\labs\07`. Run all commands in this directory.
4. Close any open files and use the Explorer pane to open the lab folder.

## Solution

The solution is in:

```text
C:\azure-tf-int\labs\solutions\07
```

Try to use this only as a last resort if you are struggling to complete the guided steps.

## Task 1. Create a resource group

### Try it yourself

1. Populate the **Task1** section of `main.tf` with an Azure provider configuration using version **4.16.0**, and a resource block creating a resource group named **RG1** in **Denmark East**.
2. Save, plan, and apply the deployment.
3. Switch to the Azure Portal to verify the deployment.

### Step-by-step

1. Using the [AzureRM 4.16.0 provider page](https://registry.terraform.io/providers/hashicorp/azurerm/4.16.0), copy the `terraform` and `provider` blocks into the **Task1** section of `main.tf`. Use provider version **4.16.0**.
2. Using the [Resource Group documentation](https://registry.terraform.io/providers/hashicorp/azurerm/4.16.0/docs/resources/resource_group), copy the `azurerm_resource_group` example block and paste it below the provider block in `main.tf`.
3. Change the resource group's `name` to `"RG1"`.
4. Change its `location` to `"Denmark East"`.
5. Save the changes.
6. Run:

   ```powershell
   terraform init
   ```

7. Run:

   ```powershell
   terraform plan
   ```

8. An error is returned because the AzureRM provider block is missing a `features` section.
9. The `features` section configures provider behaviour for certain resources. See the [Features Block documentation](https://registry.terraform.io/providers/hashicorp/azurerm/4.16.0/docs/guides/features-block) for details.
10. To accept the default behaviour, add an empty `features {}` block inside the provider block:

    ```hcl
    provider "azurerm" {
      features {}
      # Configuration options
    }
    ```

11. Beneath `features`, add your subscription ID:

    ```hcl
    subscription_id = "<your subscription id here>"
    ```

12. Save the file changes.
13. Run:

    ```powershell
    terraform plan
    ```

14. Planning should complete successfully.
15. Apply the deployment and type `yes` when prompted:

    ```powershell
    terraform apply
    ```

16. Switch to the Azure Portal and verify that resource group **RG1** exists.

## Task 2. Add a Blob Storage account and container

### Try it yourself

Using the [Blob Storage documentation](https://registry.terraform.io/providers/hashicorp/azurerm/4.16.0/docs/resources/storage_blob), update the **Task2** section of `main.tf` with:

1. An `azurerm_storage_account` resource block with a name beginning with `storageacct`, followed by a unique identifier.
2. An `azurerm_storage_container` resource block with the name `examplecontainer`. The guided example below uses `example-container` instead; use your chosen name consistently.
3. Save, plan, and apply the deployment.
4. Verify the storage account and container in the Azure Portal.

### Step-by-step

1. Using the [linked documentation](https://registry.terraform.io/providers/hashicorp/azurerm/4.16.0/docs/resources/storage_blob), copy the `azurerm_storage_account` example resource block into the **Task2** section of `main.tf`.
2. Set the storage account name to `storageacct` followed by your unique identifier. Replace the placeholder before running Terraform:

   ```hcl
   name = "storageacct<add a unique-identifier>"
   ```

3. Copy the `azurerm_storage_container` example resource block into the **Task2** section of `main.tf`.
4. Update the container name:

   ```hcl
   name = "example-container"
   ```

5. Save the changes, then plan and apply:

   ```powershell
   terraform plan
   terraform apply
   ```

   Type `yes` when prompted.

6. Verify the storage account and container in the Azure Portal.

## Task 3. Examine the file upload code

1. The Registry resource gives a simple example of copying a local file into a storage container.

   **Do not use this code in your configuration. It is shown for comparison.**

   ```hcl
   resource "azurerm_storage_blob" "example" {
     name                   = "my-awesome-content.zip"
     storage_account_name   = azurerm_storage_account.example.name
     storage_container_name = azurerm_storage_container.example.name
     type                   = "Block"
     source                 = "some-local-file.zip"
   }
   ```

2. This example has limited use. A more realistic example uploads several files and identifies their MIME types so the correct metadata is stored.
3. The supplied `main.tf` contains a **Task3** section with a more comprehensive example. All its lines are initially commented out.
4. Uncomment all code in the **Task3** section and review the following breakdown.

### MIME types

The `mime_types` local value is a map of MIME types loaded from `mime.json` in the module directory:

```hcl
locals {
  mime_types = jsondecode(file("${path.module}/mime.json"))
}
```

The map identifies the content type of a file using its extension. The example mapping contains:

```json
{
  ".txt": "text/plain",
  ".csv": "text/csv",
  ".jpeg": "image/jpeg",
  ".jpg": "image/jpeg",
  ".png": "image/png"
}
```

### `for_each` in the resource block

```hcl
for_each = fileset("${path.module}/static_files", "**/*")
```

`for_each` creates one blob resource instance for each file. `fileset()` scans `static_files` for files matching `**/*`, including files in subdirectories.

### Blob name

```hcl
name = each.key
```

`each.key` is the relative path of the current file found by `fileset()`. For example: `Teide.jpeg`.

### Blob source

```hcl
source = "${path.module}/static_files/${each.key}"
```

`source` identifies the local file to upload. `path.module` identifies the directory containing the Terraform module. For this lab, an example file is:

```text
C:\azure-tf-int\labs\07\static_files\Teide.jpeg
```

### File integrity

```hcl
content_md5 = filemd5("${path.module}/static_files/${each.key}")
```

`filemd5()` computes the file's MD5 checksum. The configuration supplies the checksum through `content_md5` for integrity verification.

### MIME type

```hcl
content_type = lookup(
  local.mime_types,
  regex("\\.[^.]+$", each.key),
  "application/octet-stream"
)
```

This assigns a content type, such as `image/jpeg` or `text/plain`, based on the file extension.

The expression `regex("\\.[^.]+$", each.key)` extracts the extension by matching a dot followed by one or more characters that are not dots, at the end of the filename. For example, `Teide.jpeg` produces `.jpeg`.

The extracted extension is used to look up the corresponding MIME type in `local.mime_types`. If that extension has no entry in the map, `lookup()` returns `application/octet-stream`.

### Code summary

The configuration uploads local files as blobs with appropriate metadata:

- **Local MIME type mapping:** `jsondecode()` converts the mappings in `mime.json` into a Terraform map.
- **Iterating over files:** `fileset()` identifies files under `static_files`, including subdirectories. The resource creates an instance for each relative path.
- **Blob name:** The `name` attribute is set from the current file's relative path.
- **Storage container details:** The supplied upload code references `azurerm_storage_account.storage_acct_1` and `azurerm_storage_container.storage_cont_1`. Ensure these references match your resource labels.
- **Blob type:** `type` is set to `"Block"`.
- **Blob source:** `source` identifies the local file to upload.
- **MD5 checksum:** `content_md5` supplies the file's MD5 checksum.
- **MIME type:** `content_type` uses the extracted extension and MIME mapping to select an appropriate content type.

### Deploy and verify

5. Save the file changes.
6. Run:

   ```powershell
   terraform plan
   ```

7. Planning should complete successfully.
8. Apply the changes and type `yes` when prompted:

   ```powershell
   terraform apply
   ```

9. In the Azure Portal, verify that the three files have been uploaded to the container and that the correct content type has been assigned to each.

## Task 4. Create an Azure Storage management policy

### Try it yourself

1. Review the sample code in the [Storage Management Policy documentation](https://registry.terraform.io/providers/hashicorp/azurerm/4.16.0/docs/resources/storage_management_policy).
2. In the **Task4** section of `main.tf`, create a policy with a single rule governing the storage tier and lifecycle of base blobs.
3. Associate the policy with your storage account.
4. Save, plan, and apply the deployment.
5. Verify the policy in the Azure Portal.

### Step-by-step

1. Using the [linked documentation](https://registry.terraform.io/providers/hashicorp/azurerm/4.16.0/docs/resources/storage_management_policy), copy the `azurerm_storage_management_policy` example resource block into the **Task4** section of `main.tf`.
2. The example contains two rules. Remove the entire `rule2` block.
3. To apply the policy to all blobs, remove `prefix_match` and `match_blob_index_tag` from the `filters` block.
4. Focus on base blobs by removing the `snapshot` block.
5. Save the changes, then plan and apply:

   ```powershell
   terraform plan
   terraform apply
   ```

   Type `yes` when prompted.

6. Verify the policy in the Azure Portal under your storage account's **Lifecycle management** page. Your storage account name will differ from the example.
7. Open the rule to view its parameters. The illustrated **Base blobs** actions are:

   | Time since last modification | Action |
   | --- | --- |
   | More than 10 days | Move to cool storage. |
   | More than 50 days | Move to archive storage. |
   | More than 100 days | Delete the blob. |

## Task 5. Create an Azure Storage access signature token

### Try it yourself

1. Review the sample code in the [Storage Account SAS documentation](https://registry.terraform.io/providers/hashicorp/azurerm/4.16.0/docs/data-sources/storage_account_sas).
2. Create a data block to generate a SAS token with:

   - Container resource types only.
   - Blob service only.
   - Validity for the whole of **2026**.
   - Read, write, and list permissions.

3. Link the SAS token to your storage account.
4. Mark the output as sensitive.
5. Save, plan, and apply the changes.

### Step-by-step

1. Using the [linked documentation](https://registry.terraform.io/providers/hashicorp/azurerm/4.16.0/docs/data-sources/storage_account_sas), copy the `azurerm_storage_account_sas` example data block into the **Task5** section of `main.tf`.
2. Set `connection_string` to your storage account's primary connection string. The example reference is:

   ```hcl
   connection_string = azurerm_storage_account.example.primary_connection_string
   ```

   Use your actual storage account resource label if it differs from `example`.

3. Remove the `signed_version` attribute.
4. In `resource_types`, set containers to `true` and all other resource types to `false`.
5. In `services`, leave blob as the only enabled service.
6. Change the date portion of `start` to **2026-01-01**.
7. Change the date portion of `expiry` to **2027-01-01**.
8. Set read, write, and list permissions to `true`. Set all other permissions to `false`.
9. Save the file changes and run:

   ```powershell
   terraform plan
   ```

10. An error should be displayed about the output block exposing a sensitive value.
11. Mark the output as sensitive by adding `sensitive = true` beneath its value:

    ```hcl
    output "sas_url_query_string" {
      value     = data.azurerm_storage_account_sas.example.sas
      sensitive = true
    }
    ```

    This suppresses the token in ordinary plan and apply output while allowing it to be explicitly requested.

12. Save the changes and run:

    ```powershell
    terraform plan
    ```

13. Planning should complete successfully.
14. Apply the changes and type `yes` when prompted:

    ```powershell
    terraform apply
    ```

15. The SAS token generated using `azurerm_storage_account_sas` is not stored or visible as a token in the Azure Portal. It is generated on the client side rather than registered as an Azure resource.

## Task 6. Using the SAS token

1. Display the SAS token:

   ```powershell
   terraform output sas_url_query_string
   ```

2. Construct the following URL on one line, substituting values for your resources. Remove the SAS token's leading `?` and any surrounding quotation marks. Ensure there are no spaces:

   ```text
   https://<storage-account-name>.blob.core.windows.net/<container-name>?restype=container&comp=list&<sas-token-without-leading-question-mark>
   ```

3. Paste the completed URL into a web browser to view the container's object details using the SAS token.

## Task 7. Lab clean-up

1. Destroy the deployed resources and type `yes` when prompted:

   ```powershell
   terraform destroy
   ```

**Congratulations, you have completed this lab.**

## Copyright

© 2026 QA Michael Coulling-Green. All rights reserved. These lab materials are provided as part of an authorised training course. Course attendees may reuse these materials for their own personal learning and reference outside of the training session. Unauthorised copying, redistribution, publication, or use of these materials to deliver training is prohibited without prior written permission from the author.
