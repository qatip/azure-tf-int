# QATIP Intermediate - Azure Lab 02

## HCL versus JSON

**Version:** 1.1.0 | **Date:** 09/06/26 | **Author:** mcgreen@qa.com

## Contents

- [Lab Objective](#lab-objective)
- [Teaching Points](#teaching-points)
- [Before you begin](#before-you-begin)
- [Step 1. Open and compare the two provisioned files](#step-1-open-and-compare-the-two-provisioned-files)
- [Step 2. Apply the JSON configuration](#step-2-apply-the-json-configuration)
- [Step 3. Modify the JSON to add another container](#step-3-modify-the-json-to-add-another-container)
- [Step 4. Apply the modified JSON configuration](#step-4-apply-the-modified-json-configuration)
- [Step 5. Lab clean-up](#step-5-lab-clean-up)

## Lab Objective

This lab compares a Terraform HCL (HashiCorp Configuration Language) configuration with a JSON-formatted Terraform file. You will compare an existing HCL file, `main.tf`, with its JSON equivalent, `json/main.tf.json`, apply the JSON configuration, and modify it to add an additional container.

## Teaching Points

1. Terraform supports both HCL and JSON formats, each catering to different use cases. HCL is designed to be human-readable and easy for developers to work with, while JSON provides a structured format that integrates well with automation tools and APIs. Understanding how to translate HCL into JSON helps students work in environments where JSON configurations are required for interoperability with external systems.
2. One of the key differences between HCL and JSON is their structure. HCL allows more concise and readable configurations using blocks, whereas JSON enforces strict key-value formatting and explicit nesting. This makes JSON more verbose but also ensures consistency in machine-parsed configurations. Comparing the two formats develops a stronger grasp of how Terraform configurations are structured and processed.
3. Modifying JSON-based Terraform configurations requires explicit syntax, including arrays for lists and clear key-value assignments. You will make structured modifications, such as adding additional containers, while maintaining correct JSON formatting. This reinforces good practice in handling Terraform configurations in JSON and avoiding syntax errors.
4. Deploying a Terraform configuration from JSON follows the same principles as HCL-based deployments, demonstrating the importance of structured and well-organized files. Through this hands-on experience, you will gain confidence in applying Terraform configurations in different formats and troubleshooting potential issues in JSON-based deployments.

## Before you begin

1. Ensure you have completed **Lab 0**.
2. If you have not completed Lab 1, start **Docker Desktop** on your remote virtual machine using the desktop shortcut. Open **Settings > General** and ensure that the Docker service is listening on port **2375 without TLS**, using **Expose daemon on tcp://localhost:2375 without TLS**. Select **Close**, then exit Settings using the lower **X** at the top right, as applicable to your version. Minimize Docker Desktop.
3. In the IDE terminal, enter:

   ```powershell
   cd C:\azure-tf-int\labs\02
   ```

4. This changes your working directory to `labs\02`. Execute commands in this directory unless instructed to change directory below.
5. Close any open files and use the Explorer pane to navigate to and open the `labs\02` folder.

## Step 1. Open and compare the two provisioned files

1. In your IDE, open both files:

   - `C:\azure-tf-int\labs\02\main.tf` - HCL format.
   - `C:\azure-tf-int\labs\02\json\main.tf.json` - JSON format.

2. Compare their structures:

   - HCL uses blocks (`{}`), while JSON uses explicit key-value pairs.
   - Compare how lists are expressed; JSON represents lists as arrays (`[]`).
   - HCL is more compact, whereas JSON requires explicit declarations.

3. Consider the following questions:

   **Which structure do you find easier to read?**

   HCL is often considered more readable because of its concise syntax, but JSON is standardized for programmatic use.

   **How does JSON handle nesting compared to HCL?**

   JSON requires explicit key-value pairs, making deeply nested structures more verbose than HCL.

   **Why does Terraform support both formats?**

   HCL is developer-friendly, while JSON allows integration with automation tools.

## Step 2. Apply the JSON configuration

1. Navigate to the JSON directory:

   ```powershell
   cd C:\azure-tf-int\labs\02\json
   ```

2. Initialize Terraform:

   ```powershell
   terraform init
   ```

3. Apply the JSON configuration:

   ```powershell
   terraform apply -auto-approve
   ```

4. Verify the deployed container:

   ```powershell
   docker ps
   ```

   The output should show the `webserver` container running on port **88**. Browse to [http://localhost:88](http://localhost:88).

5. Verify the downloaded images:

   ```powershell
   docker images
   ```

   The output shows the downloaded `httpd` image details.

## Step 3. Modify the JSON to add another container

1. Add a second container by duplicating the `"webserver"` block inside the `"docker_container"` block.
2. Insert a comma between the two sub-blocks.
3. In the duplicated block, change the identifier and name to `"webserver_2"` and change the external port from **88** to **89**.
4. The updated `main.tf.json` section should look like this. This is a fragment inside the existing `"resource"` object, not a replacement for the whole file:

   ```json
   "docker_container": {
     "webserver": {
       "image": "${resource.docker_image.httpd.image_id}",
       "name": "webserver",
       "ports": [
         {
           "internal": 80,
           "external": 88
         }
       ]
     },
     "webserver_2": {
       "image": "${resource.docker_image.httpd.image_id}",
       "name": "webserver_2",
       "ports": [
         {
           "internal": 80,
           "external": 89
         }
       ]
     }
   }
   ```

## Step 4. Apply the modified JSON configuration

1. Save the updated `main.tf.json`.
2. Apply the configuration:

   ```powershell
   terraform apply -auto-approve
   ```

3. Verify that two containers are running:

   ```powershell
   docker ps
   ```

   The output should list `webserver` on port **88** and `webserver_2` on port **89**.

4. Consider the following questions:

   **How does JSON handle nested structures differently from HCL?**

   JSON requires explicit key-value nesting, making deep structures more verbose.

   **What challenges did you face modifying the JSON?**

   JSON requires strict syntax, including commas and proper indentation, which can be error-prone.

   **Why does Terraform support both HCL and JSON?**

   HCL is more human-readable, while JSON is suited for automation and integrations.

## Step 5. Lab clean-up

1. Remove all resources, typing `yes` when prompted:

   ```powershell
   terraform destroy
   ```

2. Confirm that the containers have been destroyed:

   ```powershell
   docker ps
   ```

3. Confirm that the image has been destroyed:

   ```powershell
   docker images
   ```

4. Quit Docker Desktop using **Quit Docker Desktop** from its menu.

**Congratulations, you have completed this lab.**

## Copyright

© 2026 QA Michael Coulling-Green. All rights reserved. These lab materials are provided as part of an authorised training course. Course attendees may reuse these materials for their own personal learning and reference outside of the training session. Unauthorised copying, redistribution, publication, or use of these materials to deliver training is prohibited without prior written permission from the author.
