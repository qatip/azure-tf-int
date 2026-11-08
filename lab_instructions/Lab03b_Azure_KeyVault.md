# QATIP Intermediate - Azure Lab 03b

## Azure Key Vault

**Version:** 1.1.2 | **Date:** 04/08/26 | **Author:** mcgreen@qa.com

## Contents

- [Lab Objectives](#lab-objectives)
- [Teaching Points](#teaching-points)
- [Before you begin](#before-you-begin)
- [Step 1. Administrators set up Key Vault and SP](#step-1-administrators-set-up-key-vault-and-sp)
- [Step 2. Developers obtain SP credentials from Key Vault](#step-2-developers-obtain-sp-credentials-from-key-vault)
- [Verifying the SP account](#verifying-the-sp-account)
- [Lab clean-up](#lab-clean-up)

## Lab Objectives

This lab provides guidance and instructions on setting up an Azure Key Vault and a service principal (SP) for securely managing Terraform authentication when running Terraform from an external device. Developers retrieve the credentials from Key Vault instead of embedding them directly in their Terraform configuration or scripts.

## Teaching Points

**Step 1:** These tasks are typically handled by the security team to establish an authentication mechanism that ensures only authorized developers can retrieve the necessary service principal credentials from Azure Key Vault.

**Step 2:** These tasks are performed by developers who have been granted the required **Get** and **List** secret permissions to retrieve authentication credentials used to run Terraform commands. Developers do not have access to modify secrets but can retrieve them for authentication.

## Before you begin

1. Ensure you have completed **Lab 0**.
2. In the IDE terminal pane, enter:

   ```powershell
   cd C:\azure-tf-int\labs\03b
   ```

3. This changes your working directory to `labs\03b`. Execute all commands in this directory unless instructed otherwise.
4. Close any open files and use the Explorer pane to navigate to and open the `labs\03b` folder.

## Step 1. Administrators set up Key Vault and SP

Examine the PowerShell script `setup-terraform-keyvault.ps1`.

This script simulates tasks commonly performed by platform engineering or security teams responsible for securely provisioning Terraform authentication components.

### Stage 1. Define lab variables

The script begins by defining reusable variables, including the resource group, Azure region, Key Vault name, subscription ID, and service principal name. These values are intentionally parameterised to avoid hardcoded environment-specific values.

### Stage 2. Define helper functions

Reusable helper functions provide consistent Azure CLI execution, centralised error handling, and idempotent RBAC assignment logic. This mirrors enterprise operational scripting practices.

### Stage 3. Authenticate to Azure and select the subscription

The script authenticates interactively using:

```powershell
az login
```

It then explicitly selects the required Azure subscription to ensure all resources are deployed into the correct subscription boundary.

### Stage 4. Create or reuse the resource group

The script checks whether the resource group already exists before attempting creation. This introduces the concept of idempotent automation, where scripts can be rerun without creating duplicate resources.

### Stage 5. Create or reuse Azure Key Vault

The script checks whether the Key Vault already exists and creates it if required. The vault is configured using **Azure RBAC authorization mode**, rather than legacy vault access policies.

### Stage 6. Create or reuse the Terraform service principal

The script creates a service principal used by Terraform for non-interactive authentication. If the service principal already exists, the script rotates the client secret instead of creating a duplicate identity.

### Stage 7. Configure Azure RBAC permissions

The script assigns Azure RBAC roles to both the signed-in user and the Terraform service principal:

- The signed-in user receives **Key Vault Secrets Officer** permissions.
- The Terraform service principal receives **Key Vault Secrets User** permissions.

### Stage 8. Store Terraform credentials as Key Vault secrets

The following values are stored within Azure Key Vault:

- `Terraform-Client-ID`
- `Terraform-Client-Secret`
- `Terraform-Tenant-ID`
- `Terraform-Subscription-ID`

Terraform later consumes these values dynamically during authentication.

### Stage 9. Persist lab configuration locally for cleanup

The script stores deployment metadata locally to support automated cleanup operations later in the lab.

### Stage 10. Confirm completion

The script verifies successful completion by listing the stored secrets within Azure Key Vault.

### Actions

1. Update `setup-terraform-keyvault.ps1` with a vault name of your choice. This must be unique and can be up to **24 characters** long. Use `vault-` followed by a portion of your subscription ID, for example. Make a note of the chosen name.
2. **Denmark East** is specified as the location. If this region was unavailable when you completed Lab 3a, update line 7 with the alternative location you used there.
3. Update the script with your lab subscription ID.
4. Update `$spname`, replacing `<unique suffix>` with five random digits.
5. In production, this script would be run using cloud administrative credentials with authority to create the vault, service principal, and secrets. In the lab environment, use your existing lab credentials.
6. Run the following command to register the Key Vault namespace:

   ```powershell
   az provider register --namespace Microsoft.KeyVault
   ```

7. Run the setup script:

   ```powershell
   .\setup-terraform-keyvault.ps1
   ```

## Step 2. Developers obtain SP credentials from Key Vault

Examine the PowerShell script `retrieve-sp-credentials.ps1`.

### Stage 1. Define parameters and the secret retrieval function

The script defines parameters and a function to retrieve secrets from Azure Key Vault. It requires the vault name as an input parameter and sets a default file, `sp_credentials.env`, to store the retrieved credentials.

The `Get-SecretValue` function fetches the stored secrets. The script accesses `.SecretValue` as a `SecureString` and converts it to plaintext using `SecureStringToBSTR()` so the credentials can be passed to Terraform. The retrieved values should not be exposed in plaintext logs.

### Stage 2. Authenticate to Azure and retrieve credentials

The script authenticates to Azure using `Connect-AzAccount` and retrieves the service principal credentials stored in Key Vault.

After authentication, it fetches the client ID, client secret, tenant ID, and subscription ID using the `Get-SecretValue` function. Terraform requires these credentials to authenticate and interact with Azure resources. Retrieving the values from Key Vault avoids storing static credentials in the script.

### Stage 3. Set environment variables and store credentials in a file

Once retrieved, the script sets the following environment variables using PowerShell's `$env:` syntax:

- `ARM_CLIENT_ID`
- `ARM_CLIENT_SECRET`
- `ARM_TENANT_ID`
- `ARM_SUBSCRIPTION_ID`

These variables allow Terraform to authenticate automatically without requiring manual input.

The credentials are also stored in a local `.env` file so they can persist across sessions or be used in CI/CD pipelines where access is controlled. The file can be read to reload the environment variables without manually reconfiguring Terraform authentication each time.

**Exclude this file from version control by adding it to `.gitignore`. This prevents credentials from being accidentally committed to a repository.**

For the default filename, add this entry to `.gitignore`:

```gitignore
sp_credentials.env
```

### Actions

1. Log out of Azure CLI to demonstrate the full process:

   ```powershell
   az logout
   ```

2. Run the retrieval script, replacing `<your keyvault>` with the vault name you chose:

   ```powershell
   .\retrieve-sp-credentials.ps1 -KeyVaultName "<your keyvault>"
   ```

3. You will be prompted for credentials. In production, these would be developer credentials with authority to read from the vault. In the lab environment, use your lab credentials.
4. At this stage, the SP credentials have been downloaded and stored, and Terraform is ready to use them. Verify that the environment variables have been set:

   ```powershell
   Get-ChildItem Env:ARM_*
   ```

5. These environment variables last only for the duration of the PowerShell session. Prove this by terminating your terminal session, opening a new one, and repeating the command:

   ```powershell
   Get-ChildItem Env:ARM_*
   ```

   No values will be returned.

6. You could rerun the retrieval script when needed if the secrets were not written to a local file. In this example, they were written to a file. Return to the lab directory and run the loading script:

   ```powershell
   cd C:\azure-tf-int\labs\03b
   .\load-envs.ps1
   ```

   This reads the `.env` file values back into memory, allowing credentials to persist across sessions. If this approach is used, access to the `.env` file should be highly restricted.

## Verifying the SP account

1. Log out of Azure CLI to ensure Terraform is not relying on your lab account's Azure CLI login:

   ```powershell
   az logout
   ```

2. Run the command again:

   ```powershell
   az logout
   ```

   You should be notified:

   ```text
   There are no active accounts.
   ```

3. Review `main.tf` in your current directory. Update the provider block with your subscription ID.
4. Note that the file is configured to deploy an empty resource group for testing purposes.
5. Run:

   ```powershell
   terraform init
   terraform plan
   terraform apply --auto-approve
   ```

6. Switch to the Azure Portal and verify that resource group **RG2** exists.

## Lab clean-up

1. Destroy the resources deployed by Terraform:

   ```powershell
   terraform destroy --auto-approve
   ```

2. Run the cleanup script to delete resource group **RG1**, your service principal, and Key Vault:

   ```powershell
   .\cleanup.ps1
   ```

3. Delete the local environment variables:

   ```powershell
   Remove-Item Env:ARM_*
   ```

**Congratulations, you have completed this lab.**

## Copyright

© 2026 QA Michael Coulling-Green. All rights reserved. These lab materials are provided as part of an authorised training course. Course attendees may reuse these materials for their own personal learning and reference outside of the training session. Unauthorised copying, redistribution, publication, or use of these materials to deliver training is prohibited without prior written permission from the author.
