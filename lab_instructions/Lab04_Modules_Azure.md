# QATIP Intermediate - Azure Lab 04

## Terraform Modules

**Version:** 1.1.0 | **Date:** 09/06/26 | **Author:** mcgreen@qa.com

## Contents

- [Lab Objectives](#lab-objectives)
- [Before you begin](#before-you-begin)
- [The challenge](#the-challenge)
- [Instructions](#instructions)
- [Review](#review)
- [Demonstration deployment](#demonstration-deployment)
- [Lab clean-up](#lab-clean-up)

## Lab Objectives

- Develop reusable Terraform modules for Azure virtual networks.
- Parameterize the module using variables.
- Deploy multiple virtual networks by reusing the module with different parameters.
- Use module outputs in the root module to create dependent resources.

## Before you begin

1. In the IDE terminal pane, enter:

   ```powershell
   cd C:\azure-tf-int\labs\04
   ```

2. This changes your working directory to `labs\04`. Execute commands in this directory unless instructed otherwise.
3. Close any open files and use the Explorer pane to navigate to and open the `labs\04` folder.

## The challenge

Using `C:\azure-tf-int\labs\04` as your root directory, create a reusable module structure to deploy two Azure virtual networks into resource group **RG1**, located in **East US**. Expose outputs from the module and use them in the root module to create a subnet in each network.

### Key requirements

- Create `main.tf`, `variables.tf`, and `outputs.tf` as part of the module.
- Deploy at least two virtual networks using a module structure.
- Pass output values from the module back to the root configuration.
- Use the module outputs to create a subnet in each network.

## Instructions

### Set up the project directory

1. Ensure you have moved to the lab directory:

   ```powershell
   cd C:\azure-tf-int\labs\04
   ```

2. Create a subdirectory for the module:

   ```powershell
   mkdir modules\vnet
   ```

### Create the VNet module

3. In `C:\azure-tf-int\labs\04\modules\vnet`, create the following files.

   **main.tf**

   ```hcl
   resource "azurerm_virtual_network" "vnet" {
     name                = var.vnet_name
     address_space       = var.address_space
     location            = var.location
     resource_group_name = var.resource_group_name
   }
   ```

   **variables.tf**

   ```hcl
   variable "vnet_name" {}

   variable "address_space" {
     type = list(string)
   }

   variable "location" {}

   variable "resource_group_name" {}
   ```

   **outputs.tf**

   ```hcl
   output "vnet_id" {
     value = azurerm_virtual_network.vnet.id
   }

   output "vnet_name" {
     value = azurerm_virtual_network.vnet.name
   }

   output "vnet_address_space" {
     value = azurerm_virtual_network.vnet.address_space
   }
   ```

### Review and update the root module configuration

4. In `C:\azure-tf-int\labs\04`, update line 2 of the supplied root `main.tf` with your subscription ID.

### Initialize, review, apply, and verify

5. Run the following commands from the root directory:

   ```powershell
   cd C:\azure-tf-int\labs\04
   terraform init
   terraform plan
   terraform apply --auto-approve
   terraform state list
   ```

   Verify the deployment in the Azure Portal.

### Clean up resources

6. Run:

   ```powershell
   terraform destroy --auto-approve
   ```

## Review

This configuration uses reusable modules to deploy two Azure virtual networks, `vnet1` and `vnet2`, within a single resource group, **RG1**, located in **East US**. The root module orchestrates the deployment by calling the VNet module twice, once for each VNet, then consuming its outputs to create subnets in each network.

### Module-based approach

The reusable VNet module is stored under `C:\azure-tf-int\labs\04\modules\vnet`. Instead of defining virtual networks directly in the root module, it encapsulates VNet provisioning with configurable parameters:

| Parameter | Purpose |
| --- | --- |
| `vnet_name` | Allows different VNets to be created using the same module. |
| `address_space` | Allows each network to have a unique IP range. |
| `resource_group_name` | Associates the VNets with the specified resource group. |
| `location` | Sets the deployment location; East US is used for this challenge. |

The root module deploys two virtual networks by calling the same module twice and passing different parameters for each instance.

### Exposing and using module outputs

An essential part of the challenge is exposing outputs from the module and using them in the root module to create subnets. Output blocks in the VNet module make values such as the virtual network's name and ID available to the calling module. The root module references these outputs when creating subnets in each network.

### Scalability and reusability

Additional virtual networks can be instantiated without modifying the module itself. The structure promotes code reuse and can support future scenarios in which multiple VNets are deployed across different resource groups or locations.

## Demonstration deployment

### Overview

1. This demonstration explores a more complex use of modules to deploy **virtual networks**, **network security groups (NSGs)**, and **VNet peering**. It highlights dynamic, reusable infrastructure using Terraform modules and outputs.
2. In your IDE, navigate to `C:\azure-tf-int\labs\04\demo`.
3. Review the supplied files.
4. Update line 2 of `demo\main.tf` with your subscription ID.

### Understanding the flow logic

A single module block, `vnets`, provisions multiple VNets with multiple subnets. The values passed to the module come from variables defined in `variables.tf` and populated in `terraform.tfvars`:

```hcl
module "vnets" {
  for_each            = var.vnets
  source              = "./modules/vnet"
  vnet_name           = each.value.name
  address_space       = each.value.address_space
  location            = each.value.location
  resource_group_name = azurerm_resource_group.example.name

  subnets = [for k, v in var.subnets[each.key] : {
    name           = k
    address_prefix = v
  }]
}
```

The expression `for_each = var.vnets` creates a module instance for each entry in `var.vnets`, two in this example. Each instance receives values from its corresponding VNet entry:

```hcl
vnets = {
  vnet1 = {
    name          = "vnet-01"
    address_space = ["10.0.0.0/16"]
    location      = "East US"
  }

  vnet2 = {
    name          = "vnet-02"
    address_space = ["10.1.0.0/16"]
    location      = "West Europe"
  }
}
```

The `vnet1` instance creates a VNet named `vnet-01`, with address range `10.0.0.0/16`, in **East US**.

The `subnets` variable is a nested map. Its outer keys match the VNet keys, while each inner map contains the subnets for that VNet:

```hcl
subnets = {
  vnet1 = {
    apps = "10.0.1.0/24"
    data = "10.0.2.0/24"
  }

  vnet2 = {
    apps = "10.1.1.0/24"
    data = "10.1.2.0/24"
  }
}
```

When calling the module, only the subnets belonging to the current VNet are passed down. The following `for` expression converts the selected inner map into a list of objects:

```hcl
subnets = [for k, v in var.subnets[each.key] : {
  name           = k
  address_prefix = v
}]
```

- `each.key` is the current VNet key, `vnet1` or `vnet2`, from the module's `for_each` expression.
- `var.subnets[each.key]` selects only the subnets for that VNet.
- The expression converts the selected map into a list of objects with `name` and `address_prefix` attributes.

The `vnet1` instance therefore creates `vnet-01` with address range `10.0.0.0/16` and subnets `apps` (`10.0.1.0/24`) and `data` (`10.0.2.0/24`).

### Module inputs, resources, and outputs

Inside the VNet module, variables defined in `variables.tf` receive the values passed from the root module. Defaults are used where defined; required module inputs must be supplied by the caller.

**Module variables.tf**

```hcl
variable "resource_group_name" {}

variable "vnet_name" {}

variable "address_space" {
  type = list(string)
}

variable "location" {}

variable "subnets" {
  type = list(object({
    name           = string
    address_prefix = string
  }))
  default = []
}
```

These values are used by the module's `main.tf` to deploy the VNet and its subnets:

```hcl
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "subnet" {
  for_each = { for s in var.subnets : s.name => s }

  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [each.value.address_prefix]
}
```

Selected VNet and subnet values are returned to the root module through outputs. The PDF illustrates the output structure with the following excerpt:

```hcl
output "vnet_details" {
  value = {
    id = azurerm_virtual_network.vnet.id
  }
}

output "subnets" {
  value = { for s in azurerm_subnet.subnet : s.name => s.id }
}
```

The peering configuration later also consumes `vnet_details.name`. Ensure that the supplied demo module's `vnet_details` output exposes the VNet name as well as its ID before enabling peering:

```hcl
output "vnet_details" {
  value = {
    id   = azurerm_virtual_network.vnet.id
    name = azurerm_virtual_network.vnet.name
  }
}
```

The flow is:

- One module block defines all VNet instances.
- `for_each` creates a module instance for each entry in `var.vnets`.
- Subnets are grouped by VNet in a map of maps.
- The `for` expression passes only the appropriate subnets to each VNet instance.
- Inside the VNet module, another `for_each` creates the subnets dynamically.

### Initialize and deploy the demonstration

5. Run:

   ```powershell
   cd C:\azure-tf-int\labs\04\demo
   terraform init
   ```

   Note how the VNet module is initialized. A `modules` folder is created under `.terraform`. Its `modules.json` file identifies the module, its source, and its source directory. For a remote module, a copy of the module files would also be downloaded and saved locally.

6. Run:

   ```powershell
   terraform plan
   terraform apply --auto-approve
   ```

7. List the managed resources:

   ```powershell
   terraform state list
   ```

8. Open the Terraform console:

   ```powershell
   terraform console
   ```

9. Enter the following expression to view the module instances and their outputs:

   ```hcl
   module.vnets
   ```

10. Exit the console:

    ```text
    exit
    ```

11. The VNets and their associated subnets are now driven by input data rather than explicit, per-resource coding. Test this by editing `terraform.tfvars` and adding a third subnet, `mgmt`, to the `vnet2` entry in the existing `subnets` map:

    ```hcl
    vnet2 = {
      apps = "10.1.1.0/24"
      data = "10.1.2.0/24"
      mgmt = "10.1.3.0/24"
    }
    ```

12. Review, apply, and list the updated resources:

    ```powershell
    terraform plan
    terraform apply --auto-approve
    terraform state list
    ```

    The plan should show one subnet to add.

13. Verify that the new `mgmt` subnet exists in the Azure Portal.
14. Remove the `mgmt` subnet from the `vnet2` entry and apply the changes:

    ```powershell
    terraform plan
    terraform apply --auto-approve
    ```

### Network security group provisioning

15. Enable the NSG module block in `demo\main.tf`. The PDF identifies lines **30** and **36** as the comment-marker lines to change; check the surrounding markers so the module block becomes active.

    Modules do not automatically share their resources with one another. The NSG configuration needs information about VNets created by a separate module. The root module orchestrates this by drawing information from the VNet module and passing it to the NSG module.

    The logic is:

    - The VNet module's `outputs.tf` exposes values for the VNets it created.
    - The root `main.tf` uses this information when calling the `nsgs` module, creating an instance for each VNet.
    - `modules\nsg\variables.tf` receives the input values.
    - `modules\nsg\main.tf` deploys NSGs using those variables.

16. Initialize the new module:

    ```powershell
    terraform init
    ```

    Note how the NSG module is now initialized.

17. Review and apply:

    ```powershell
    terraform plan
    terraform apply --auto-approve
    ```

18. List the managed resources:

    ```powershell
    terraform state list
    ```

19. In the Azure Portal, verify that the NSGs exist and that the subnets are not yet associated with them.

### NSG association provisioning

20. Enable the NSG association resource in `demo\main.tf`. The PDF identifies lines **40** and **60** as the comment-marker lines to change. The resource shown is:

    ```hcl
    resource "azurerm_subnet_network_security_group_association" "nsg_association" {
      for_each = merge([
        for vnet_key, vnet in module.vnets : {
          for subnet_name, subnet_id in vnet.subnets :
          "${vnet_key}-${subnet_name}" => {
            vnet_key  = vnet_key
            subnet_id = subnet_id
          }
        }
      ]...)

      subnet_id                 = each.value.subnet_id
      network_security_group_id = module.nsgs[each.value.vnet_key].nsg_id

      depends_on = [
        module.vnets,
        module.nsgs
      ]
    }
    ```

    The logic is:

    - Loop over each VNet module instance and extract its subnets.
    - Store the VNet key and subnet ID in a structured map.
    - Build a unique `for_each` key using the VNet key and subnet name, such as `vnet1-apps`.
    - Combine the generated maps using `merge([... ]...)`.
    - Look up the matching NSG using `each.value.vnet_key`.

21. Review and apply:

    ```powershell
    terraform plan
    terraform apply --auto-approve
    ```

22. List the managed resources:

    ```powershell
    terraform state list
    ```

23. Switch to the Azure Portal and verify the subnet-to-NSG associations:

    | NSG | Virtual network | Associated subnets |
    | --- | --- | --- |
    | `vnet-01-nsg` | `vnet-01` | `apps` (`10.0.1.0/24`), `data` (`10.0.2.0/24`) |
    | `vnet-02-nsg` | `vnet-02` | `apps` (`10.1.1.0/24`), `data` (`10.1.2.0/24`) |

### Network peering provisioning

24. Enable the peering resource in `demo\main.tf`. The PDF identifies lines **62** and **74** as the comment-marker lines to change. The resource shown is:

    ```hcl
    resource "azurerm_virtual_network_peering" "peerings" {
      for_each = {
        peer1to2 = { local = "vnet1", remote = "vnet2" }
        peer2to1 = { local = "vnet2", remote = "vnet1" }
      }

      name                      = each.key
      resource_group_name       = azurerm_resource_group.example.name
      virtual_network_name      = module.vnets[each.value.local].vnet_details.name
      remote_virtual_network_id = module.vnets[each.value.remote].vnet_details.id
    }
    ```

    This defines resources of type `azurerm_virtual_network_peering`. Instead of writing two separate resource blocks, `for_each` creates two peering instances.

    **How the values are resolved**

    The `for_each` map contains two entries. Their keys, `peer1to2` and `peer2to1`, identify the two peering relationships. Each entry holds the keys of its local and remote VNet module instances.

    | Peering instance | `each.value.local` | `each.value.remote` |
    | --- | --- | --- |
    | `peer1to2` | `vnet1` | `vnet2` |
    | `peer2to1` | `vnet2` | `vnet1` |

    - `name = each.key` sets the peering name to `peer1to2` or `peer2to1`.
    - `resource_group_name` is the same for both instances because both VNets belong to the same resource group.
    - `module.vnets[each.value.local].vnet_details.name` resolves to the local VNet's name: `module.vnets["vnet1"].vnet_details.name` for `peer1to2`, or `module.vnets["vnet2"].vnet_details.name` for `peer2to1`.
    - `module.vnets[each.value.remote].vnet_details.id` resolves to the remote VNet's ID: `module.vnets["vnet2"].vnet_details.id` for `peer1to2`, or `module.vnets["vnet1"].vnet_details.id` for `peer2to1`.

    Terraform therefore creates one peering from `vnet1` to `vnet2` and another from `vnet2` to `vnet1`. Each resource instance receives the appropriate name, local virtual network name, and remote virtual network ID.

25. Review and apply:

    ```powershell
    terraform plan
    terraform apply --auto-approve
    ```

26. List the managed resources:

    ```powershell
    terraform state list
    ```

27. Confirm both peerings in the Azure Portal.

## Lab clean-up

1. From the demonstration directory, destroy all demonstration resources:

   ```powershell
   cd C:\azure-tf-int\labs\04\demo
   terraform destroy --auto-approve
   ```

**Congratulations, you have completed this lab.**

## Copyright

© 2026 QA Michael Coulling-Green. All rights reserved. These lab materials are provided as part of an authorised training course. Course attendees may reuse these materials for their own personal learning and reference outside of the training session. Unauthorised copying, redistribution, publication, or use of these materials to deliver training is prohibited without prior written permission from the author.
