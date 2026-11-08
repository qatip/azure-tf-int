# QATIP Intermediate - Azure Lab 01

## A sample Terraform deployment

**Version:** 1.1.0 | **Date:** 07/06/26 | **Author:** mcgreen@qa.com

## Contents

- [Lab Objectives](#lab-objectives)
- [Teaching Points](#teaching-points)
- [Before you begin](#before-you-begin)
- [Task 1. Review the sample Terraform configuration file](#task-1-review-the-sample-terraform-configuration-file)
- [Task 2. Run Terraform and test](#task-2-run-terraform-and-test)
- [Task 3. Examine the state file](#task-3-examine-the-state-file)
- [Task 4. Destroy the deployment](#task-4-destroy-the-deployment)

## Lab Objectives

In this lab, you will:

- Review a simple sample Terraform deployment configuration file.
- Deploy a local Docker image and container.
- Test the container.
- Modify the deployment.
- Test the modified deployment.
- Destroy the deployment.

## Teaching Points

This lab introduces you to Terraform and guides you through using it to interact with locally installed Docker. It introduces providers, used to indicate the infrastructure that will be managed, and the structure and composition of Terraform files. You will review an example Terraform file before initializing the client, planning, and applying the deployment. You will then modify the deployment before eventually destroying it.

## Before you begin

1. Ensure you have completed **Lab 0**.
2. On your remote virtual machine, start **Docker Desktop** using the desktop shortcut. Open **Settings > General** and ensure that the Docker service is listening on port **2375 without TLS**, using the **Expose daemon on tcp://localhost:2375 without TLS** setting.
3. Select **Close**, then exit Settings using the lower **X** at the top right, as applicable to your version of Docker Desktop.
4. Verify that no containers exist. Your Docker Desktop version may differ, so the layout of this and subsequent Docker command outputs may vary slightly.
5. Verify that no local images exist.
6. Minimize Docker Desktop, keeping it running in the background.

## Task 1. Review the sample Terraform configuration file

1. In the IDE, open `C:\azure-tf-int\labs\01\main.tf`.

   The configuration shown in the lab is:

   ```hcl
   terraform {
     required_providers {
       docker = {
         source  = "kreuzwerker/docker"
         version = "4.2.0"
       }
     }
   }

   provider "docker" {
     host = "tcp://localhost:2375"
   }

   # Pull the image
   resource "docker_image" "httpd" {
     name = "httpd:latest"
   }

   # Create a container
   resource "docker_container" "webserver" {
     image = docker_image.httpd.image_id
     name  = "webserver"

     ports {
       internal = 80
       external = 88
     }
   }
   ```

### Breaking it down

#### Defining the Terraform block

The `terraform` block specifies the providers required for the configuration. Here, the provider is Docker, indicating that we want to use Terraform to manage Docker resources. The `source` identifies the Docker provider component to download during initialization, and `version` indicates which version is required.

#### Initializing the provider

The `provider` block details parameters used when initializing the Docker provider. The configuration needed depends on the platform on which Docker is running. We are using Docker Desktop for Windows, where the Docker service is accessible using TCP port **2375**.

#### Pulling the Docker image

The `docker_image` resource is one of two resource blocks that indicate what we want Terraform to instruct Docker to create. Here, we define an image to pull from Docker Hub: `httpd:latest`, an Apache web server image.

#### Creating the Docker container

The `docker_container` resource defines a container named `webserver`, with internal port **80** mapped to external port **88**.

A Docker container is created from a Docker image. The expression `docker_image.httpd.image_id` references the image that we asked Docker to pull. This is an example of one resource block referencing another. It also tells Terraform to wait for Docker to download the image before creating the container from it. This is known as an **implicit dependency**: the container depends on the image existing.

## Task 2. Run Terraform and test

1. In your IDE terminal, ensure you are in the correct working directory, then initialize Terraform:

   ```powershell
   cd C:\azure-tf-int\labs\01
   terraform init
   ```

2. Run the following command and review what will be created:

   ```powershell
   terraform plan
   ```

3. Apply the configuration, typing `yes` when prompted:

   ```powershell
   terraform apply
   ```

4. If prompted, configure Windows Defender to allow access.
5. Switch to Docker Desktop and verify the image download and container creation.
6. Switch back to the IDE terminal and list the images:

   ```powershell
   docker images
   ```

   The `httpd` image is the image Terraform instructed Docker to download. The `U` indicator, where displayed, indicates that it is currently in use.

7. List the running containers:

   ```powershell
   docker ps
   ```

   The container named `webserver` is the one Terraform instructed Docker to start using the downloaded image. Note the last few digits of its unique container ID. Your ID will differ from the example in the source lab.

8. In a new browser tab within your virtual desktop, access [http://127.0.0.1:88](http://127.0.0.1:88).
9. View the **It works!** response from the Apache web server's `index.html` page.
10. We will now modify the deployment by changing the external port from **88** to **8088**. Some resource changes can be applied to an existing resource, while others require destruction of the original and creation of a replacement. We will see whether a port change modifies or recreates this resource.
11. Return to `main.tf` and change the external port on line 25 to `8088`:

    ```hcl
    ports {
      internal = 80
      external = 8088
    }
    ```

12. Run the following command again and review the changes:

    ```powershell
    terraform plan
    ```

    The port change will force the current container to be deleted and a new one created. The plan will indicate that `ports` forces replacement.

13. Apply the change, typing `yes` when prompted:

    ```powershell
    terraform apply
    ```

14. Browse to [http://127.0.0.1:8088](http://127.0.0.1:8088). This should return **It works!**, showing that the new container is accessible on port **8088**.
15. List running containers again:

    ```powershell
    docker ps
    ```

    Note that your **CONTAINER ID** has changed. For this port configuration change, Terraform destroyed the original container and deployed a replacement using the same image. Whether Terraform updates or replaces a resource depends on the resource itself and the changes made.

## Task 3. Examine the state file

1. When `terraform apply` is run for the first time, a persistent record of the resources Terraform deploys and manages is created in a state file, `terraform.tfstate`. The file is updated whenever you ask Terraform to create, change, or destroy resources thereafter. By default, it is in your working directory. Open `terraform.tfstate` in the IDE and examine its contents.

## Task 4. Destroy the deployment

1. Run the following command, review the output, and type `yes`:

   ```powershell
   terraform destroy
   ```

2. Confirm that your container has been deleted:

   ```powershell
   docker ps
   ```

3. Confirm that your image has been deleted:

   ```powershell
   docker images
   ```

4. Revisit the state file and view its now reduced content.
5. Close the Docker Desktop window.

**Congratulations, you have completed this lab.**

## Copyright

© 2026 QA Michael Coulling-Green. All rights reserved. These lab materials are provided as part of an authorised training course. Course attendees may reuse these materials for their own personal learning and reference outside of the training session. Unauthorised copying, redistribution, publication, or use of these materials to deliver training is prohibited without prior written permission from the author.
