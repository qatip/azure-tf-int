# QATIP Intermediate - Azure Lab 08

## Terraform Pipelining with Jenkins

**Version:** 1.1.0 | **Date:** 09/06/26 | **Author:** mcgreen@qa.com

## Contents

- [Lab Objectives](#lab-objectives)
- [Teaching Points](#teaching-points)
- [Solution](#solution)
- [Before you begin](#before-you-begin)
- [Task 1. Create a Jenkins virtual machine](#task-1-create-a-jenkins-virtual-machine)
- [Task 2. Create a storage account for remote state](#task-2-create-a-storage-account-for-remote-state)
- [Task 3. Create a GitHub account and repository](#task-3-create-a-github-account-and-repository)
- [Task 4. Configure Jenkins](#task-4-configure-jenkins)
- [Task 5. Add Azure credentials to Jenkins](#task-5-add-azure-credentials-to-jenkins)
- [Task 6. Configure a Jenkins pipeline job](#task-6-configure-a-jenkins-pipeline-job)
- [Task 7. Verify the pipeline run and explore Jenkins](#task-7-verify-the-pipeline-run-and-explore-jenkins)
- [Task 8. Update the Jenkins pipeline](#task-8-update-the-jenkins-pipeline)
- [Task 9. Configure a Jenkins destroy pipeline, time permitting](#task-9-configure-a-jenkins-destroy-pipeline-time-permitting)
- [Task 10. Lab cleanup](#task-10-lab-cleanup)

## Lab Objectives

In this lab, you will:

1. Provision a storage account for use as a Terraform remote backend.
2. Deploy and configure an Ubuntu Jenkins instance.
3. Create and run Jenkins pipelines to deploy and destroy Azure resources using Terraform.

## Teaching Points

This lab demonstrates how businesses can control Terraform deployments through change control and release mechanisms. GitHub provides version control, while Jenkins runs the deployment pipeline. A production workflow can include review and approval before changes are released.

Alternative approaches include:

| Platform | Approach described in the lab |
| --- | --- |
| GitLab CI/CD | Built-in CI/CD, runners that execute Terraform plans and applies, and Terraform integration for state management and monitoring. |
| Azure DevOps | Azure Pipelines combined with Azure Repos or GitHub, supporting staged workflows and approvals. |
| GitHub Actions | Workflows triggered by repository events, such as pushes and pull requests, using GitHub-hosted runners. |
| Spinnaker | Application delivery and infrastructure automation, with Terraform integration and support for multiple clouds. |

## Solution

There is no preconfigured solution to this lab. Ask your instructor if you have difficulty completing a task, and verify each task before moving on.

## Before you begin

Complete the Azure lab setup instructions. In the VSC terminal and Explorer, open the Lab 08 folder:

```powershell
cd C:\azure-tf-int\labs\08
```

## Task 1. Create a Jenkins virtual machine

1. In the Azure Portal, ensure resource group **RG1** does not exist. If it is present, manually delete it before proceeding. In the IDE terminal, run the supplied script to create an Ubuntu VM for Jenkins:

   ```powershell
   C:\azure-tf-int\labs\08\createjenkinsvm.ps1
   ```

2. Record the VM's public IP address. You can also retrieve it from the VM's page in the Azure Portal when needed.
3. Jenkins requires connectivity over port **8080**. Add an inbound rule:

   ```powershell
   az vm open-port --port 8080 --resource-group RG1 --name VM1
   ```

   In production, these rules would be more granular.

4. Copy the installation script to the VM using SCP. Replace `<vm_ip>` with the VM's public IP address:

   ```powershell
   cd C:\azure-tf-int\labs\08
   scp ./setup_jenkins_azure.sh azureuser@<vm_ip>:/home/azureuser/
   ```

5. Connect to the VM using SSH:

   ```powershell
   ssh azureuser@<vm_ip>
   ```

6. In the SSH session, run all four lines below. They select the script directory, make the script executable, convert Windows line endings to Linux line endings, and run the installer:

   ```bash
   cd /home/azureuser/
   chmod +x setup_jenkins_azure.sh
   sed -i 's/\r$//' setup_jenkins_azure.sh
   ./setup_jenkins_azure.sh
   ```

7. Continue with the next tasks while Ubuntu updates and Jenkins installs.

## Task 2. Create a storage account for remote state

Create an Azure storage account and blob container for use as the Terraform remote backend.

1. Navigate to the Azure Portal.
2. Search for and select **Storage accounts**.
3. Select **Create** and configure:

   | Setting | Value |
   | --- | --- |
   | Resource group | Existing group **RG1** |
   | Storage account name | `jenkinsstate` followed by your unique identifier |
   | Region | **Denmark East** |
   | Performance | **Standard** |
   | Replication | **Locally-redundant storage (LRS)** |

4. Leave the other settings at their defaults. Select **Review + create**, then **Create**.
5. Once the account exists, open it and create a blob container with the following settings. Refresh the browser if the page does not display correctly:

   | Setting | Value |
   | --- | --- |
   | Name | `terraform-state` |
   | Public access level | **Private** |

6. Record the storage account name and container name for later use.

## Task 3. Create a GitHub account and repository

Create a GitHub repository containing the Jenkinsfile and Terraform configuration that Jenkins will use.

### Task 3a. Sign up to GitHub

If you already have a GitHub account you are prepared to use, continue to **Task 3b**.

1. Navigate to [GitHub](https://github.com/).
2. Enter a personal email address that is not already associated with GitHub and select **Sign up for GitHub**.
3. Enter a password and a unique username.
4. Record your chosen username and password in your session-info file for safekeeping, as directed in the lab.
5. Complete the challenge to prove you are human.
6. Retrieve the launch code sent to your email address and enter it.
7. Sign in using your new account when prompted.
8. Complete the questionnaire.
9. When asked to select a subscription, select **Continue for free**.

### Task 3b. Create a public repository

1. Select **Create repository**.
2. Enter a repository name of your choice, select **Public**, enable **Add a README file**, and select **Create repository**.
3. Select **Add file > Upload files**.
4. Select `Jenkinsfile` from `C:\azure-tf-int\labs\08`.
5. Select **Commit changes**.
6. Repeat the upload and commit process for `main.tf` from the same folder.
7. Verify that both `Jenkinsfile` and `main.tf` are listed in the repository.
8. Copy your repository URL.
9. Open `Jenkinsfile` and select the edit icon.
10. On line **13**, replace `<your repo url>` with your repository URL. Select **Commit changes**, then confirm the commit.

    The repository checkout line follows this pattern:

    ```groovy
    git branch: 'main', url: '<your repo url>'
    ```

11. Open `main.tf` for editing.
12. Review lines **24-26**. They define the resource Jenkins will deploy: an empty resource group. A production configuration would normally contain more resources.
13. On line **12**, replace `<your subscription id here>` with your lab subscription ID.
14. In the backend's `storage_account_name` setting, around line **18**, replace `<your storage account>` with the account name from Task 2. The backend configuration shown in the lab is:

    ```hcl
    terraform {
      backend "azurerm" {
        resource_group_name  = "RG1"
        storage_account_name = "<your storage account>"
        container_name       = "terraform-state"
        key                  = "terraform.tfstate"
      }
    }
    ```

    Update the existing block rather than adding a duplicate.

15. Commit the changes.
16. Leave the GitHub tab open; you will return to it later.

## Task 4. Configure Jenkins

1. Open Jenkins in a new browser tab, replacing `<vm_ip>` with your Jenkins VM's public IP address:

   ```text
   http://<vm_ip>:8080
   ```

2. Once installation finishes, run the command displayed by the setup script in your SSH session to reveal the initial Jenkins admin password:

   ```bash
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```

   Copy the returned password into the **Unlock Jenkins** screen and select **Continue**.

3. Select **Install suggested plugins**.
4. On **Create First Admin User**, select **Skip and continue as admin**.
5. Select **Save and Finish**.
6. Select **Start using Jenkins**.

## Task 5. Add Azure credentials to Jenkins

1. Terraform running in Jenkins needs credentials to interact with Azure. This lab uses a service principal.
2. Locate and record your subscription ID in the Azure Portal.
3. In your IDE terminal, finish the SSH session:

   ```bash
   exit
   ```

4. Back at the local terminal, create a service principal. Replace `<S_ID>` with your subscription ID and `<four-digits>` with four random digits:

   ```powershell
   az ad sp create-for-rbac --name "jenksp-<four-digits>" --role Contributor --scopes /subscriptions/<S_ID>
   ```

5. Retain the returned service principal details. Your values will differ from the lab example.
6. In Jenkins, select **Manage Jenkins**.
7. Select **Credentials**.
8. Navigate through **System > Global**, then select **Add Credentials**.
9. Set **Kind** to **Secret text**.
10. From the service principal output, copy `appId` without its surrounding quotes into **Secret**. Set **ID** to `azure_sp_client_id`.
11. Select **Create**.
12. Repeat the process to add the remaining three credentials. All four mappings must be:

    | Secret value | Jenkins credential ID |
    | --- | --- |
    | Service principal `appId` | `azure_sp_client_id` |
    | Service principal `password` | `azure_sp_client_secret` |
    | Service principal `tenant` | `azure_tenant_id` |
    | Azure subscription ID | `azure_subscription_id` |

13. Verify that all credential IDs match these values exactly.

## Task 6. Configure a Jenkins pipeline job

1. Return to the Jenkins dashboard and select **+ New Item**.
2. Enter **Terraform Pipeline** as the item name.
3. Select **Pipeline** as the item type.
4. Select **OK**.
5. Scroll to the **Pipeline** section. Change **Definition** from **Pipeline script** to **Pipeline script from SCM**.
6. Set **SCM** to **Git**.
7. Enter your GitHub repository URL in **Repository URL**.
8. Under **Branches to build**, change **Branch Specifier** from `*/master` to `*/main`.
9. Select **Save**.
10. Select **Build Now**.

## Task 7. Verify the pipeline run and explore Jenkins

1. Return to the Jenkins dashboard. Refresh until the pipeline run has a result showing success or failure.
2. Open the dropdown menu beside build **#1** and select **Pipeline Overview**.
3. Examine the stages and their success or failure indicators. The example shows **Checkout SCM**, **Clone Repository**, **Install Terraform**, **Terraform Init**, **Terraform Plan**, and **Terraform Apply**.
4. Examine each stage's console logs by selecting the stage and toggling its log display in the green area.
5. Explore the Jenkins interface, using the breadcrumb menu to navigate. Return to the main dashboard when finished.
6. In the Azure Portal, open the `terraform-state` container and verify that `terraform.tfstate` exists.
7. Verify that the new resource group **RG2**, configured in `main.tf`, exists.

## Task 8. Update the Jenkins pipeline

In a production workflow, developers would check out the repository locally, edit Terraform files, and submit changes for approval. Approved changes would be merged and deployed by a new pipeline run. Jenkins can be triggered manually or by a GitHub webhook.

This task simplifies the editing process: make changes directly in GitHub, trigger one run manually, and then configure a webhook to trigger a run automatically.

### Trigger a run manually

1. Return to your GitHub repository and sign in if needed.
2. Open `main.tf` for editing.
3. Change the name of the resource group to be created from **RG2** to **RG3** and commit the change.
4. In Jenkins, select the play icon to schedule a manual pipeline run.
5. Observe progress in **Build Executor Status**.
6. Once the run succeeds, build **#2** should be listed. Refresh if needed, open its dropdown menu, and select **Pipeline Console**.
7. Examine the **Terraform Apply** logs. The old resource group was replaced because its name cannot be changed in place.
8. In the Azure Portal, verify deletion of the old resource group and creation of **RG3**. Refresh if needed.

### Configure a webhook and trigger a run automatically

9. In Jenkins, select the pipeline on the dashboard and choose **Configure**.
10. Under **Build Triggers**, select **GitHub hook trigger for GITScm polling**, then select **Save**.
11. In your GitHub repository, open **Settings > Webhooks > Add webhook**. Reauthenticate if prompted.
12. Set **Payload URL** to the following, replacing `<jenkins-public-ip>` with your VM's public IP address:

    ```text
    http://<jenkins-public-ip>:8080/github-webhook/
    ```

13. Set **Content type** to **application/json**.
14. Select **Disable SSL verification** for this lab environment.
15. Verify the settings and select **Add webhook**.
16. Edit `main.tf` in GitHub, change the resource group name to **RG4**, and commit the changes.
17. Return to the webhook settings and confirm that GitHub successfully delivered the push notification to Jenkins.
18. In Jenkins, return to the dashboard and look for the third pipeline run. Wait for completion and refresh periodically if it is still running.
19. In the Azure Portal, verify that **RG4** has been created. Refresh the display if needed.

## Task 9. Configure a Jenkins destroy pipeline, time permitting

1. On the Jenkins dashboard, select **+ New Item**.
2. Enter **Terraform Pipeline Destroy** as the item name.
3. Select **Pipeline** as the item type.
4. Select **OK**.
5. Scroll to the **Pipeline** section and change **Definition** to **Pipeline script from SCM**.
6. Set **SCM** to **Git**.
7. Enter your GitHub repository URL.
8. Under **Branches to build**, change **Branch Specifier** from `*/master` to `*/main`.
9. Set **Script Path** to:

   ```text
   destroy/Jenkinsfile
   ```

10. Save the pipeline, but **do not build it yet**.
11. Switch to GitHub.
12. Create a new file named `destroy/Jenkinsfile`. Entering `destroy/` as part of the filename creates the folder.
13. In your IDE, open the supplied destroy pipeline file:

    ```text
    C:\azure-tf-int\labs\08\destroy\Jenkinsfile
    ```

    Copy its contents into your new GitHub file. Ensure you use the Jenkinsfile from the **destroy** folder.

14. Update line **13** with your repository URL, then commit the changes.
15. Return to Jenkins and build **Terraform Pipeline Destroy**.
16. This Jenkinsfile requires approval before deletion proceeds. Open the running build and select **Console Output**.
17. When the run pauses for approval, select **Yes** to confirm deletion.
18. Once destruction completes, verify in the Azure Portal that the resource group deployed by the pipeline has been deleted.

## Task 10. Lab cleanup

1. In the Azure Portal, manually delete resource group **RG1**. It contains the Jenkins VM and remote-state storage created outside this Terraform configuration.
2. In the Azure Portal, navigate to **Microsoft Entra ID > App registrations** and delete the Jenkins service principal's app registration.

**Congratulations, you have completed this lab.**

Delete your GitHub repository at your own discretion.

## Copyright

© 2026 QA Michael Coulling-Green. All rights reserved. These lab materials are provided as part of an authorised training course. Course attendees may reuse these materials for their own personal learning and reference outside of the training session. Unauthorised copying, redistribution, publication, or use of these materials to deliver training is prohibited without prior written permission from the author.
