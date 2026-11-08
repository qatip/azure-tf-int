# QATIP Intermediate - Azure Lab 0

## Environment Setup

**Version:** 2.0.0 | **Date:** 29/06/26 | **Author:** mcgreen@qa.com

## Contents

- [Lab Objectives](#lab-objectives)
- [Teaching Points](#teaching-points)
- [Task 1. Accessing the lab environment](#task-1-accessing-the-lab-environment)
- [Task 2. Installing Class Files](#task-2-installing-class-files)
- [Task 3. Configuring your IDE](#task-3-configuring-your-ide)
- [Task 4. Logging into Azure](#task-4-logging-into-azure)
- [Task 5. Arranging your remote desktop](#task-5-arranging-your-remote-desktop)

## Lab Objectives

In this lab, you will:

- Launch your lab environment to access your virtual machine.
- Download class files into your lab virtual machine.
- Launch and configure Visual Studio Code (VSC) in your lab virtual machine ahead of running subsequent labs.

## Teaching Points

This lab will set up your lab environment. It should be run at the beginning of each day of the class before attempting any other labs. The lab environment has a time limit of **8 hours 30 minutes**, after which it will be decommissioned. At this point, you will need to restart the lab environment via the QA Portal and run this setup again.

## Task 1. Accessing the lab environment

1. Access your QA Platform session booking via the MyQA links that should have been emailed to you.
2. Two lab bookings should have been made for you: one for Azure labs and another for AWS labs. This document assumes that Azure is your preferred cloud provider, so follow the link to **QA Terraform in Practice (Intermediate) - Azure**.
3. If necessary, complete the prerequisite checks before selecting **Access the lab**.
4. Click **Start/Restart lab**.
5. This starts provisioning your lab resources. An estimated provisioning time is displayed. Wait for your resources to be provisioned before continuing.
6. Once your desktop is initialized, collapse the sidebar. **Do not click Submit until you no longer need the remote desktop: this terminates the lab session.**
7. Use **Actions** if you wish to restart or end the lab session.

## Task 2. Installing Class Files

1. In the remote VM, open an **Administrator PowerShell** session.
2. Enter the following commands:

   ```powershell
   cd C:\
   git clone https://github.com/qatip/azure-tf-int.git
   ```

3. You should now have a `C:\azure-tf-int` folder containing the course manual, lab instructions, lab files, and solution files.
4. Close the PowerShell session window.
5. You can now open the course manual and lab instruction PDFs using a web browser.

## Task 3. Configuring your IDE

1. In the VM, open **Visual Studio Code** using the desktop shortcut.
2. If required, change your colour scheme and select **Mark Done**.
3. Close the **Getting Started** and **Chat** windows.
4. On the left-hand vertical menu, choose **Extensions**, or press **Ctrl+Shift+X**.
5. Search for **Terraform**.
6. Choose the **HashiCorp Terraform** extension and click **Install**.
7. Once complete, close the tab.
8. Navigate back to **Explorer**, the top icon on the left-hand activity bar.
9. Select **File > Open Folder**, navigate to and select `C:\azure-tf-int`. Select **Yes** to trust the authors of files in this folder.
10. Start a terminal session by selecting **Terminal > New Terminal**.
11. Close any Getting Started files. You should now see your lab folders and have a terminal session open.
12. Enable Auto Save using **File > Auto Save**.
13. As you perform each lab and execute commands in your terminal session, move into the appropriate directory using the `cd` command. For Lab 1, for example:

    ```powershell
    cd C:\azure-tf-int\labs\01
    ```

14. Confirm that Terraform has already been installed on the remote VM:

    ```powershell
    terraform -version
    ```

    Version **1.14.6** is acceptable, so do not attempt to update it.

## Task 4. Logging into Azure

1. When required to run Terraform commands from the IDE terminal, you will need to authenticate to Azure unless you already have an active session.
2. Enter the following command in your terminal session:

   ```powershell
   az login
   ```

3. A dialog box should open, prompting you for credentials. It may be obscured behind VSC if you have it maximized.
4. Select **Workplace or school account**.
5. Enter the username and password supplied to you by your instructor.
6. Follow the prompts to set up multifactor authentication. This is a one-time task.
7. Select **No, this app only** when prompted **Sign in to all apps and websites on this device?**
8. The login dialog box will close. Return to VSC and press **Enter** to accept the default subscription and tenant selection.
9. During the course, you may need to reauthenticate and supply your account details, including your subscription ID. The source lab recommends creating a local text document containing your lab username, password, and subscription ID. Reveal your subscription ID using:

   ```powershell
   az account show
   ```

10. Using your preferred browser, navigate to [the Azure Portal](https://portal.azure.com) and sign in.

## Task 5. Arranging your remote desktop

1. Arrange your desktop so you can easily switch between your web browser and VSC. Use the browser to view your course manual, lab instructions, the Azure Portal, and other web resources. Use VSC to create Terraform files and run Terraform commands.
2. Alternatively, install the **vscode-pdf** extension into VSC to view PDFs within the IDE itself.

**Congratulations, you have completed this lab.**

## Copyright

© 2026 QA Michael Coulling-Green. All rights reserved. These lab materials are provided as part of an authorised training course. Course attendees may reuse these materials for their own personal learning and reference outside of the training session. Unauthorised copying, redistribution, publication, or use of these materials to deliver training is prohibited without prior written permission from the author.
