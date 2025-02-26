## STAGE 1 ##
# Define Variables
$resourceGroup = "RG1"
$location = "West Europe"
$keyVaultName = "<key_name>"
$subscriptionId = "<sub_id>"
$spName = "terraform-sp"

# Login to Azure
Write-Host "Logging into Azure..."
az login > $null  # Suppress login output

# Create Resource Group
Write-Host "Creating Resource Group..."
az group create --name $resourceGroup --location $location > $null

# Verify Resource Group
Write-Host "Verifying Resource Group..."
az group show --name $resourceGroup --query '{id:id, name:name, location:location}'

## STAGE 2 ##
# Create Key Vault
Write-Host "Creating Azure Key Vault..."
az keyvault create --name $keyVaultName --resource-group $resourceGroup --location $location > $null

# Verify Key Vault
Write-Host "Verifying Azure Key Vault..."
az keyvault show --name $keyVaultName --query "{id:id, name:name, location:location}"

## STAGE 3 ##
# Create Service Principal
Write-Host "Creating Service Principal..."
$spOutput = az ad sp create-for-rbac --name $spName --role "Contributor" --scopes "/subscriptions/$subscriptionId" -o json | ConvertFrom-Json

$appId = $spOutput.appId
$clientSecret = $spOutput.password
$tenantId = $spOutput.tenant

# Masked Output
Write-Host "Service Principal Created - App ID: $(($appId -replace '^(.{4}).*(.{4})$', '$1****$2'))"
Write-Host "Tenant ID: $(($tenantId -replace '^(.{4}).*(.{4})$', '$1****$2'))"
Write-Host "Client Secret: [HIDDEN]"

# Store Service Principal Credentials in Key Vault (Masking Output)
Write-Host "Storing Service Principal credentials in Key Vault..."
az keyvault secret set --vault-name $keyVaultName --name "Terraform-Client-ID" --value $appId > $null
az keyvault secret set --vault-name $keyVaultName --name "Terraform-Client-Secret" --value $clientSecret > $null
az keyvault secret set --vault-name $keyVaultName --name "Terraform-Tenant-ID" --value $tenantId > $null
az keyvault secret set --vault-name $keyVaultName --name "Terraform-Subscription-ID" --value $subscriptionId > $null

# Verify Stored Secrets (Masking Output)
Write-Host "Listing stored secrets in Key Vault (Names Only)..."
az keyvault secret list --vault-name $keyVaultName --query "[].{name:name}" -o table

## STAGE 4 ##
# Grant Key Vault Access to the Service Principal
Write-Host "Granting Key Vault access to the Service Principal..."
az keyvault set-policy --name $keyVaultName --spn $appId --secret-permissions get list > $null

# Verify Key Vault Access Policy (Masking Output)
Write-Host "Verifying Key Vault access policy..."
az keyvault show --name $keyVaultName --query "{id:id, name:name, properties:properties.accessPolicies}" > $null

Write-Host "Setup Complete! Terraform service principal secrets are securely stored in Azure Key Vault."
