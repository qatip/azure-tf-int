# QATIP Intermediate - Azure Lab 05

## Terraform Checks and Validations

**Version:** 1.2.0 | **Date:** 08/11/26 | **Author:** mcgreen@qa.com

## Contents

- [Overview](#overview)
- [Before you begin](#before-you-begin)
- [Phase 1. VM size precondition check](#phase-1-vm-size-precondition-check)
- [Phase 2. Storage account name validation](#phase-2-storage-account-name-validation)
- [Phase 3. Cleanup](#phase-3-cleanup)

## Overview

This lab introduces Terraform validation mechanisms, including input variable validation and resource conditions. You will reject an invalid VM size, validate a storage account name, and use a postcondition to detect when configuration logic changes an initially valid name into a noncompliant value.

## Before you begin

1. Ensure you have completed **Lab 0**.
2. Navigate to the lab directory:

   ```powershell
   cd C:\azure-tf-int\labs\05
   ```

3. Update `main.tf` with your subscription ID.
4. Update `terraform.tfvars`, adding a unique suffix to the storage account name.

## Phase 1. VM size precondition check

### Purpose

**What we are doing:** Using Terraform's `validation` block inside a variable definition to restrict input values for VM sizes. Although this phase is titled a precondition check in the source lab, the mechanism demonstrated here is **input variable validation**.

**Why it matters:** In cloud environments with cost controls or policy restrictions, not all VM sizes are allowed. This validation protects users from accidentally requesting expensive or disallowed SKUs by checking the input value before attempting to deploy the VM.

### Steps

1. Review the supplied `variables.tf` file. Two variables are declared:

   - `vm_size`: must be one of the three listed sizes.
   - `storage_account_name`: must begin with `lab`.

   Both variables have validation rules.

2. Review `terraform.tfvars`. Values for both variables are present. The VM size is one of the three permitted sizes, and the storage account name begins with `lab`.
3. In `terraform.tfvars`, change the VM size  to `Standard_B4s`:

   ```hcl
   vm_size = "Standard_B4s"
   ```

4. Initialize Terraform and run a plan:

   ```powershell
   terraform init
   terraform plan
   ```

   The plan should fail with an error indicating an invalid VM size choice.

5. In `terraform.tfvars`, reset the VM size to the original permitted value:

   ```hcl
   vm_size = "Standard_B2s_v2"
   ```

## Phase 2. Storage account name validation

### Purpose

**What we are doing:** Checking the storage account name at two points:

1. An input validation rule ensures that the supplied storage account name starts with `lab`.
2. A resource postcondition ensures that the name evaluated for the storage account still meets this rule after the configuration's naming logic runs.

**Why it matters:** Logic inside a Terraform configuration, such as `replace()` or `lower()`, can transform an input value. Checking both the input and the resulting resource value helps ensure that configuration logic does not unintentionally break naming rules.

### Steps

1. In `terraform.tfvars`, remove `lab` from the beginning of the storage account name. Keep the rest of your unique name.
2. Run:

   ```powershell
   terraform plan
   ```

   This should fail the input validation check with an error indicating an invalid storage account name.

3. Restore the `lab` prefix in the storage account name so that it complies with the validation rule. Planning should now succeed:

   ```powershell
   terraform plan
   ```

4. Now introduce an error in the naming logic. The initial input will still pass validation, but the resulting storage account name will not meet the rule.
5. In `main.tf`, navigate to line **75** and change the second occurrence of `lab` to `test`. This generates a storage account name that differs from the original variable value.
6. Run:

   ```powershell
   terraform plan
   ```

   This should fail the resource postcondition with an error indicating an invalid name. The resulting storage account name begins with `test`, so the postcondition fails even though the input variable began with `lab`.

7. Undo the change to line 75 of `main.tf`.
8. Plan and apply to verify that the valid resources deploy successfully:

   ```powershell
   terraform plan
   terraform apply --auto-approve
   ```

## Phase 3. Cleanup

1. Destroy the deployed resources:

   ```powershell
   terraform destroy
   ```

   Review the proposed destruction and type `yes` when prompted.

**Congratulations, you have completed this lab.**

## Copyright

© 2026 QA Michael Coulling-Green. All rights reserved. These lab materials are provided as part of an authorised training course. Course attendees may reuse these materials for their own personal learning and reference outside of the training session. Unauthorised copying, redistribution, publication, or use of these materials to deliver training is prohibited without prior written permission from the author.
