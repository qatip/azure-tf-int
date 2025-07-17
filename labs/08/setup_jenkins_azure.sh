#!/bin/bash

set -e  # Exit if any command fails

JENKINS_VERSION="2.479.3"  # Change this to the version you need

echo "Updating system and installing OpenJDK 17..."
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y openjdk-17-jdk

echo "Adding Jenkins repository..."
sudo apt-get install -y curl gnupg lsb-release
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update

echo "Installing Jenkins version $JENKINS_VERSION..."
sudo apt-get install -y jenkins=$JENKINS_VERSION
sudo apt-mark hold jenkins  # Prevent automatic updates

echo "Starting and enabling Jenkins service..."
sudo systemctl enable --now jenkins
sudo systemctl restart jenkins

echo "Installing unzip..."
sudo apt-get install -y unzip

echo "Adding Azure CLI repository and installing Azure CLI..."
curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/azure-cli-archive-keyring.gpg > /dev/null
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/azure-cli-archive-keyring.gpg] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt-get update
sudo apt-get install -y azure-cli

echo "Updating sudoers to allow Jenkins to move files without a password..."
if ! sudo grep -q "jenkins ALL=(ALL) NOPASSWD: /bin/mv" /etc/sudoers; then
    echo "jenkins ALL=(ALL) NOPASSWD: /bin/mv" | sudo tee -a /etc/sudoers
else
    echo "Jenkins sudoers rule already exists."
fi

echo "Setup completed successfully!"

echo "########################################################################"
echo "# To retrieve the Jenkins initial admin password, enter the command:   #"
echo "# sudo cat /var/lib/jenkins/secrets/initialAdminPassword               #"
echo "########################################################################"
