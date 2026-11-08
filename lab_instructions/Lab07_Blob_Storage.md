# QATIP Intermediate - Azure Lab 07

## Managing Azure Storage using Terraform

**Version:** 1.1.0 | **Date:** 09/06/26 | **Author:** mcgreen@qa.com

## Contents

- [Lab Objectives](#lab-objectives)
- [Teaching Points](#teaching-points)
- [Before you begin](#before-you-begin)
- [Solution](#solution)
- [Task 1. Create a resource group](#task-1-create-a-resource-group)
- [Task 2. Add a Blob Storage account and container](#task-2-add-a-blob-storage-account-and-container)
- [Task 3. Examine the file upload code](#task-3-examine-the-file-upload-code)
- [Task 4. Create an Azure Storage management policy](#task-4-create-an-azure-storage-management-policy)
- [Task 5. Create an Azure Storage shared access signature token](#task-5-create-an-azure-storage-shared-access-signature-token)
- [Task 6. Use the SAS token](#task-6-use-the-sas-token)
- [Task 7. Lab clean-up](#task-7-lab-clean-up)

## Lab Objectives

In this lab, you will use Terraform to create the following:

- Resource group.
- Storage account.
- Blob container.
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

3. Run all commands from this directory.
4. Close any open files and use the Explorer pane to navigate to and open the `labs\07` folder.

## Solution

The solution is in:

```text
C:\azure-tf-int\labs\solutions\07
```

Try to use this only as a last resort if you are struggling to complete the guided steps.

## Task 1. Create a resource group

Reference: [Blob Storage resource documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_blob).

### Try it yourself

1. Populate the **Task1** section of `main.tf` with an Azure provider block and a resource block creating a resource group named **RG1** in **East US**.
2. Save, plan, and apply the deployment.
3. Switch to the Azure Portal to verify the deployment.

### Step-by-step

1. In the Terraform Registry, select the provider's **Overview** tab and copy the `terraform` and `provider` blocks into the **Task1** section of `main.tf`.

   The provider example shown in the PDF is:

   ```hcl
   terraform {
     required_providers {
       azurerm = {
         source  = "hashicorp/azurerm"
         version = "4.74.0"
       }
     }
   }

   provider "azurerm" {
     # Configuration options
   }
   ```

2. Use your browser's **Back** button to return to the `azurerm_storage_blob` documentation.
3. Copy the `azurerm_resource_group` example block and paste it below the provider block.
4. Set the resource group's `name` to `"RG1"`.
5. Set its `location` to `"East US"`.
6. Save the changes.
7. Initialize Terraform:

   ```powershell
   terraform init
   ```

8. Run a plan:

   ```powershell
   terraform plan
   ```

9. An error is returned because the AzureRM provider block is missing a `features` section.
10. The `features` section configures provider behaviour for certain resources. See the [Features Block documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/features-block) for details.
11. To accept the default behaviour, add an empty `features {}` block inside the provider block.
12. Beneath `features`, add your subscription ID. The completed provider block should look like this:

    ```hcl
    provider "azurerm" {
      features {}
      subscription_id = "<your subscription id here>"
    }
    ```

13. Save the changes.
14. Run:

    ```powershell
    terraform plan
    ```

15. Planning should complete successfully.
16. Apply the configuration and type `yes` when prompted:

    ```powershell
    terraform apply
    ```

17. In the Azure Portal, verify that resource group **RG1** exists.

## Task 2. Add a Blob Storage account and container

Reference: [Blob Storage resource documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_blob).

### Try it yourself

Update the **Task2** section of `main.tf` with:

1. An `azurerm_storage_account` resource block using the name `storageacct` followed by a unique identifier.
2. An `azurerm_storage_container` resource block. Use `example-container` as the container name for the guided steps below.
3. Save, plan, and apply the deployment.
4. Verify the storage account and container in the Azure Portal.

### Step-by-step

1. Open the linked Terraform Registry documentation.
2. Copy the `azurerm_storage_account` example resource block into the **Task2** section of `main.tf`.
3. Update its `name` to `storageacct` followed by your unique identifier:

   ```hcl
   name = "storageacct<add-a-unique-identifier>"
   ```

   Replace the placeholder with your identifier before running Terraform.

4. Copy the `azurerm_storage_container` example resource block into the **Task2** section.
5. Set the container name:

   ```hcl
   name = "example-container"
   ```

6. Save the changes, then plan and apply:

   ```powershell
   terraform plan
   terraform apply
   ```

   Type `yes` when prompted.

7. Verify the storage account and container in the Azure Portal.

## Task 3. Examine the file upload code

1. The Registry documentation gives a simple example of copying a local file into a storage container.

   **Do not add the following example to your configuration. It is shown for comparison only.**

   ```hcl
   resource "azurerm_storage_blob" "example" {
     name                   = "my-awesome-content.zip"
     storage_account_name   = azurerm_storage_account.example.name
     storage_container_name = azurerm_storage_container.example.name
     type                   = "Block"
     source                 = "some-local-file.zip"
   }
   ```

2. This illustrates uploading one file. A more realistic example uploads several files and identifies their MIME types so the correct content-type metadata is stored.
3. The **Task3** section of the supplied `main.tf` contains a more comprehensive example. Its lines are initially commented out.
4. Uncomment all code in the **Task3** section and review it using the explanations below.

### MIME types

The local value `mime_types` is a map of file extensions to MIME types, loaded from `mime.json` in the module directory:

```hcl
locals {
  mime_types = jsondecode(file("${path.module}/mime.json"))
}
```

The JSON mapping includes entries such as:

```json
{
  ".txt": "text/plain",
  ".csv": "text/csv",
  ".jpeg": "image/jpeg",
  ".jpg": "image/jpeg",
  ".png": "image/png"
}
```

The mapping determines a file's content type from its extension.

### Iterating over files

The blob resource uses `for_each` to create one resource instance for each file:

```hcl
for_each = fileset("${path.module}/static_files", "**/*")
```

`fileset()` finds files under `static_files` matching `**/*`, including files in subdirectories. Each file is identified by a path relative to that directory.

### Blob name

```hcl
name = each.key
```

`each.key` is the relative path of the current file returned by `fileset()`. For example, it could be `Teide.jpeg`.

### Blob source

```hcl
source = "${path.module}/static_files/${each.key}"
```

This identifies the local file to upload. `path.module` identifies the directory containing the module in which the expression appears. In this lab, an example file is:

```text
C:\azure-tf-int\labs\07\static_files\Teide.jpeg
```

### File integrity

```hcl
content_md5 = filemd5("${path.module}/static_files/${each.key}")
```

`filemd5()` computes the file's MD5 checksum. The code supplies this checksum as the blob's `content_md5` value for integrity verification.

### MIME type assignment

```hcl
content_type = lookup(
  local.mime_types,
  regex("\\.[^.]+$", each.key),
  "application/octet-stream"
)
```

The regex extracts the file extension by matching a dot followed by one or more characters that are not dots, at the end of the filename. For example:

| Input | Extracted extension |
| --- | --- |
| `Teide.jpeg` | `.jpeg` |

`lookup()` then retrieves the corresponding MIME type from `local.mime_types`. If that extension has no entry in the map, it uses `application/octet-stream`.

### Code summary

The upload configuration:

- Loads the MIME mapping with `jsondecode()`.
- Iterates over files in `static_files` with `fileset()` and `for_each`.
- Uses each relative file path as the blob name.
- Refers to the existing storage account and container. The supplied code uses the resource labels `azurerm_storage_account.storage_acct_1` and `azurerm_storage_container.storage_cont_1`; references must match the labels in your configuration.
- Sets the blob `type` to `"Block"`.
- Identifies the local source file for each blob.
- Computes the file's MD5 checksum.
- Assigns a content type based on its extension.

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

9. In the Azure Portal, verify that the three files have been uploaded to the container and that each has the correct content type. For example, a JPEG file should have content type `image/jpeg`.

## Task 4. Create an Azure Storage management policy

Reference: [Storage Management Policy documentation](https://registry.terraform.io/providers/hashicorp/azurerm/4.16.0/docs/resources/storage_management_policy).

### Try it yourself

1. Review the sample code in the linked documentation.
2. In the **Task4** section of `main.tf`, create a policy with a single rule governing the storage tier and lifecycle of base blobs.
3. Associate the policy with your storage account.
4. Save, plan, and apply the deployment.
5. Verify the policy in the Azure Portal.

### Step-by-step

1. Open the linked Terraform Registry documentation.
2. Copy the `azurerm_storage_management_policy` example resource block into the **Task4** section of `main.tf`.
3. The example contains two rules. Remove the entire `rule2` block.
4. Apply the policy to all blobs by removing `prefix_match` and `match_blob_index_tag` from the `filters` block.
5. Focus on base blobs by removing the `snapshot` block.
6. Save, plan, and apply:

   ```powershell
   terraform plan
   terraform apply
   ```

   Type `yes` when prompted.

7. In the Azure Portal, open your storage account's **Lifecycle management** page and verify that the rule exists. Your storage account name will differ from the example.
8. Open the rule and inspect its **Base blobs** parameters. The PDF illustrates:

   | Time since last modification | Action |
   | --- | --- |
   | More than 10 days | Move to cool storage. |
   | More than 50 days | Move to archive storage. |
   | More than 100 days | Delete the blob. |

## Task 5. Create an Azure Storage shared access signature token

Reference: [Storage Account SAS data source documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/storage_account_sas).

### Try it yourself

1. Review the sample code in the linked documentation.
2. Create a data block to generate a SAS token with the following configuration:

   - Container resource types only.
   - Blob service only.
   - Valid for the whole of **2026**.
   - Read, write, and list permissions.

3. Link the SAS token to your storage account.
4. Mark its output as sensitive.
5. Save, plan, and apply the changes.

### Step-by-step

1. Open the linked Terraform Registry documentation.
2. Copy the `azurerm_storage_account_sas` example data block into the **Task5** section of `main.tf`.
3. Set `connection_string` to your storage account's primary connection string. The source lab illustrates:

   ```hcl
   connection_string = azurerm_storage_account.example.primary_connection_string
   ```

   Replace `example` with the actual storage account resource label in your configuration if it differs.

4. Remove the `signed_version` attribute from the copied example.
5. In `resource_types`, set containers to `true` and the other resource types to `false`.
6. In `services`, leave blob as the only enabled service.
7. Change the date portion of `start` to **2026-01-01**.
8. Change the date portion of `expiry` to **2027-01-01**.
9. Set read, write, and list permissions to `true`. Set all other permissions to `false`.
10. Save the changes and run:

    ```powershell
    terraform plan
    ```

11. If the supplied output block has not yet been marked sensitive, Terraform should return an error about exposing a sensitive value through an output.
12. Add `sensitive = true` to the output block:

    ```hcl
    output "sas_url_query_string" {
      value     = data.azurerm_storage_account_sas.example.sas
      sensitive = true
    }
    ```

    This suppresses the token in ordinary plan and apply output while allowing it to be explicitly requested.

13. Save the changes and run:

    ```powershell
    terraform plan
    ```

14. Planning should complete successfully.
15. Apply the changes and type `yes` when prompted:

    ```powershell
    terraform apply
    ```

16. The SAS token generated by the `azurerm_storage_account_sas` data source is not stored or displayed as a token in the Azure Portal. It is generated on the client side rather than registered as an Azure resource.

## Task 6. Use the SAS token

1. Explicitly display the SAS token:

   ```powershell
   terraform output sas_url_query_string
   ```

   To obtain the token without Terraform's surrounding quotation marks, use:

   ```powershell
   terraform output -raw sas_url_query_string
   ```

2. Construct the following URL on one line, replacing the placeholders with values for your resources. Remove the token's leading `?` and any surrounding quotation marks. Ensure there are no spaces:

   ```text
   https://<storage-account-name>.blob.core.windows.net/<container-name>?restype=container&comp=list&<sas-token-without-leading-question-mark>
   ```

3. Paste the completed URL into a web browser. The SAS token authorizes the request, and the browser should display an XML listing of the container's blobs.

## Task 7. Lab clean-up

1. Destroy the deployed resources and type `yes` when prompted:

   ```powershell
   terraform destroy
   ```

**Congratulations, you have completed this lab.**

## Copyright

© 2026 QA Michael Coulling-Green. All rights reserved. These lab materials are provided as part of an authorised training course. Course attendees may reuse these materials for their own personal learning and reference outside of the training session. Unauthorised copying, redistribution, publication, or use of these materials to deliver training is prohibited without prior written permission from the author.
