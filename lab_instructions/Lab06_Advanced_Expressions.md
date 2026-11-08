# QATIP Intermediate - Azure Lab 06

## Advanced Terraform Expressions, Functions, and Regular Expressions

**Version:** 1.1.0 | **Date:** 09/06/26 | **Author:** mcgreen@qa.com

## Contents

- [Lab Objectives](#lab-objectives)
- [Before you begin](#before-you-begin)
- [Challenge 1. Creating a resource group with dynamic naming and tagging](#challenge-1-creating-a-resource-group-with-dynamic-naming-and-tagging)
- [Challenge 2. Standardizing resource names using regular expressions](#challenge-2-standardizing-resource-names-using-regular-expressions)

## Lab Objectives

This multi-challenge lab integrates expressions, dynamic blocks, Terraform functions, and regular expressions to create flexible and reusable infrastructure configurations in Azure. By the end of this lab, you will:

- Implement conditional expressions to control resource creation.
- Use string, numeric, and date/time functions to standardize resource naming, tagging, and configuration.
- Use regular expressions (regex) to standardize inconsistent resource names.
- Validate outputs using `terraform console`.

## Before you begin

1. Ensure you have completed **Lab 0**.
2. In the IDE terminal pane, enter:

   ```powershell
   cd C:\azure-tf-int\labs\06
   ```

3. There is a subdirectory for each challenge. Navigate to the appropriate folder as you attempt each challenge. Make all file changes and run all commands in the relevant challenge subdirectory.

## Challenge 1. Creating a resource group with dynamic naming and tagging

### Scenario

Create a reusable configuration that meets the following requirements:

- Creates a resource group with a name in the range **RG1** to **RG6**.
- Adds an **Environment** tag that is always uppercase and restricted to **DEV**, **PROD**, or **TEST**.
- Adds a second tag, **UpdatedOn**, containing the date of resource group creation or update in **YYYY-MM-DD** format.
- Uses `terraform.tfvars` to supply the resource group name and environment values.
- Validates that the proposed resource group name is within the range `RG1` through `RG6` and that the environment, after normalization to uppercase, is `DEV`, `PROD`, or `TEST`.

### Goal: Define the Terraform configuration for the resource group

Update the files provided in:

```text
C:\azure-tf-int\labs\06\challenge1
```

Attempt to create a deployment that complies with the scenario.

Work from the challenge directory:

```powershell
cd C:\azure-tf-int\labs\06\challenge1
```

### Validation checks

Run Terraform plan operations and review the output to ensure that the resource group name, **Environment** tag, and **UpdatedOn** tag comply with the requirements:

```powershell
terraform plan
```

#### Test invalid parameters

Update `terraform.tfvars` with:

- Resource group name: `RG8`.
- Environment: `plan`.

Run:

```powershell
terraform plan
```

This should produce validation error messages.

#### Test valid parameters

Update `terraform.tfvars` with:

- Resource group name: `RG1`.
- Environment: `dev`.

Run:

```powershell
terraform plan
```

This should succeed, with the environment converted to uppercase as **DEV**.

### Hints

- Use `format()` and `upper()` for consistency.
- Use `timestamp()` to capture the date and time.
- Use `formatdate()` to generate the creation or update date tag.
- Use `contains()` to validate the resource group name.

### Proposed solution

A proposed solution can be found at:

```text
C:\azure-tf-int\labs\solutions\06\challenge1
```

### Post-challenge clean-up

Remove any resources created during this challenge:

```powershell
terraform destroy
```

## Challenge 2. Standardizing resource names using regular expressions

### Scenario

You have been assigned to the cloud infrastructure team at a company migrating virtual machines from multiple departments to Azure. Each department has used its own naming convention, leading to inconsistent VM names:

| Existing name | Existing format |
| --- | --- |
| `dev-finance.db01` | `stage-project.name` |
| `infra_prod_appserver` | `project_stage_name` |
| `sales-test_db02` | `project-stage_name` |
| `infra_prod_web01` | `project_stage_name` |
| `test.backup.storage03` | `stage.project.name` |

The business has mandated the following naming convention for all cloud-hosted VMs:

```text
[environment]-[project]-[name]
```

For example: `prod-finance-db01`.

### Goal: Load a JSON file and process the data using regex

Update the files provided in:

```text
C:\azure-tf-int\labs\06\challenge2
```

Work from the challenge directory:

```powershell
cd C:\azure-tf-int\labs\06\challenge2
```

Use Terraform functions to process a JSON file containing inconsistent VM names. Reconstruct the names using regular expressions so they follow the mandated naming convention.

Your configuration should:

1. Load `resource-names.json` using `jsondecode()`.
2. Construct regex patterns dynamically from the known stages, `dev`, `prod`, and `test`, and projects, `finance`, `sales`, `infra`, and `backup`.
3. Extract the environment, project, and machine name from the JSON data using `regex()`.
4. Generate new names in accordance with the naming convention.
5. Display output listing the original names and their converted names, matching the following examples:

   | Original name | Converted name |
   | --- | --- |
   | `dev-finance.db01` | `dev-finance-db01` |
   | `infra_prod_appserver` | `prod-infra-appserver` |
   | `infra_prod_web01` | `prod-infra-web01` |
   | `sales-test_db02` | `test-sales-db02` |
   | `test.backup.storage03` | `test-backup-storage03` |

**There is no requirement to create these virtual machines at this stage.**

### Hints

- Use `jsondecode(file("./resource-names.json"))` to read the JSON file.
- Use `join("|", ...)` with the known stages or projects to construct regex alternatives for matching.
- Use `try(regex(pattern, name), "default_value")` to avoid errors when a match is missing.

### Proposed solution

A proposed solution can be found at:

```text
C:\azure-tf-int\labs\solutions\06\challenge2
```

**Congratulations, you have completed this lab.**

## Copyright

© 2026 QA Michael Coulling-Green. All rights reserved. These lab materials are provided as part of an authorised training course. Course attendees may reuse these materials for their own personal learning and reference outside of the training session. Unauthorised copying, redistribution, publication, or use of these materials to deliver training is prohibited without prior written permission from the author.
