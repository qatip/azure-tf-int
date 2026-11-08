# QATIP Intermediate - Azure Lab 03a

## Service Principals

**Version:** 1.2.0 | **Date:** 08/11/26 | **Author:** mcgreen@qa.com

## Contents

- [Overview](#overview)
- [Before you begin](#before-you-begin)
- [Phase 0. Create a limited service principal](#phase-0-create-a-limited-service-principal)
- [Phase 1. Run Terraform with the limited SP identity](#phase-1-run-terraform-with-the-limited-sp-identity)
- [Phase 2. Assign Contributor to the service principal](#phase-2-assign-contributor-to-the-service-principal)

## Overview

This lab introduces secure, least-privilege access using Azure service principals (SPs). You will:

- Create a service principal with limited permissions scoped to the subscription.
- Use SP credentials via environment variables.
- Run Terraform operations and observe RBAC restrictions.
- Upgrade permissions and reattempt deployments.

## Before you begin

1. Navigate to the lab directory:

   ```powershell
   cd C:\azure-tf-int\labs\03a
   ```

## Phase 0. Create a limited service principal

### Purpose

**What we are doing:** Creating a new non-human identity, a service principal, to run Terraform. It represents a limited automation identity, as might be used in CI/CD pipelines.

**Why it matters:** Instead of using our full-access lab account, we want to simulate realistic access boundaries, mimicking how secure organizations prevent developers and automation tools from having unrestricted rights.

**Environment variable usage:** Instead of hardcoding secrets, we inject them into the environment. This aligns with DevSecOps best practices and is supported natively by the Terraform AzureRM provider.

### Steps

1. Update line 2 of `main.tf`, replacing `<your subscription id>` with your lab subscription ID.
2. Create the service principal with **Reader** access, scoped to your subscription. Replace `<sub_id>` with your lab subscription ID and `<4 digits>` with four random digits of your choice:

   ```powershell
   az ad sp create-for-rbac --name terraform-sp-<4 digits> --role Reader --scopes /subscriptions/<sub_id>
   ```

3. Note down the displayed output, as you will need it later. Create the following environment variables using the returned values:

   ```powershell
   $env:ARM_CLIENT_ID = "<appId>"
   $env:ARM_CLIENT_SECRET = "<password>"
   $env:ARM_SUBSCRIPTION_ID = "<your subscription id>"
   $env:ARM_TENANT_ID = "<tenant>"
   ```

4. Adopt the SP identity:

   ```powershell
   az logout
   az login --service-principal --username $env:ARM_CLIENT_ID --password=$env:ARM_CLIENT_SECRET --tenant $env:ARM_TENANT_ID
   ```

   You should see `"type": "servicePrincipal"` in the output.

## Phase 1. Run Terraform with the limited SP identity

### Purpose

**What we are doing:** Attempting to deploy infrastructure using Terraform under this limited SP identity.

**Why it matters:** This phase is expected to fail, intentionally. It highlights that authenticating to Azure is not enough: role assignments define what you are allowed to do. It also encourages developers to review error messages meaningfully and connect failures to permissions.

### Steps

1. Run:

   ```powershell
   terraform init
   terraform plan
   terraform apply --auto-approve
   ```

   > **Resource-provider registration note from the source lab:** This lab uses Azure provider version 4.16, which will automatically register the networking resource provider. If using version >5.0, the source lab instructs you to run the following command if you receive errors about registration of the Azure networking resource provider, then retry the plan and apply:

   ```powershell
   az provider register --namespace Microsoft.Network
   ```

2. Expect `terraform apply` to fail with authorization errors.

## Phase 2. Assign Contributor to the service principal

### Purpose

**What we are doing:** Temporarily switching back to the lab account to assign **Contributor** rights to the SP.

**Why it matters:** This demonstrates the RBAC model in action: a principal's capabilities change dynamically based on role assignments. It mirrors how platform teams might approve temporary elevated access to unblock automation or development pipelines.

### Steps

1. Re-adopt your lab identity:

   ```powershell
   az logout
   az login
   ```

2. Insert your application ID and subscription ID, then run:

   ```powershell
   az role assignment create --assignee <appId> --role Contributor --scope /subscriptions/<sub_id>
   ```

3. Re-adopt the SP identity:

   ```powershell
   az logout
   az login --service-principal --username $env:ARM_CLIENT_ID --password=$env:ARM_CLIENT_SECRET --tenant $env:ARM_TENANT_ID
   ```

4. Retry:

   ```powershell
   terraform plan
   terraform apply --auto-approve
   ```

5. Terraform should now succeed. Use the Azure Portal to view the new resources.

   If you receive errors regarding subscription registration in **Denmark East**, use the following command to list available regions. Update `main.tf` accordingly before retrying the plan and apply:

   ```powershell
   az account list-locations --query "[].{Region:name,DisplayName:displayName}" --output table
   ```

6. Remove the deployed resources:

   ```powershell
   terraform destroy --auto-approve
   ```

7. Identify the service principal object ID. Replace `<appid>` with your application ID:

   ```powershell
   az ad sp show --id <appid> --query "{ objectId:id}" -o table
   ```

   This command returns the **service principal object ID**. Keep the application ID for the app registration deletion below.

8. Attempt to delete the service principal and app registration:

   ```powershell
   az ad sp delete --id <object id>
   az ad app delete --id <appid>
   ```

   The deletion attempts should fail because the service principal being used does not have sufficient permissions.

9. Re-adopt your lab identity:

   ```powershell
   az logout
   az login
   ```

10. Delete the service principal:

    ```powershell
    az ad sp delete --id <object id>
    ```

11. Delete the app registration:

    ```powershell
    az ad app delete --id <appid>
    ```

12. Delete the local environment variables:

    ```powershell
    Remove-Item Env:ARM_*
    ```

**Congratulations, you have completed this lab.**

## Conversion notes

- Corrected the title spelling from “Service Principles” to “Service Principals”.
- Restored the missing `$` in `$env:ARM_TENANT_ID` in the second service principal login command.
- Clarified that `az ad sp show` returns the service principal object ID, rather than the app registration object ID.
- The source lab's provider-version and registration guidance is retained above; it has not been technically revised as part of this format conversion.

## Copyright

© 2026 QA Michael Coulling-Green. All rights reserved. These lab materials are provided as part of an authorised training course. Course attendees may reuse these materials for their own personal learning and reference outside of the training session. Unauthorised copying, redistribution, publication, or use of these materials to deliver training is prohibited without prior written permission from the author.
