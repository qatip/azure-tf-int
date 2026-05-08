## STAGE 1 ##
# Define Variables
$ErrorActionPreference = "Stop"

$resourceGroup  = "RG1"
$location       = "West Europe"
$keyVaultName   = "<your vault name>"
$subscriptionId = "<your subscription id>"
$spName         = "terraform-sp-<unique suffix>"

function Invoke-AzCli {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command
    )

    Invoke-Expression $Command

    if ($LASTEXITCODE -ne 0) {
        throw "Azure CLI command failed: $Command"
    }
}

Write-Host "Logging into Azure..."
az login | Out-Null

Write-Host "Selecting subscription..."
Invoke-AzCli "az account set --subscription `"$subscriptionId`""

Write-Host "Creating Resource Group..."
Invoke-AzCli "az group create --name `"$resourceGroup`" --location `"$location`" --output none"

Write-Host "Verifying Resource Group..."
az group show `
  --name $resourceGroup `
  --query "{id:id, name:name, location:location}" `
  -o table


## STAGE 2 ##
Write-Host "Creating Azure Key Vault in RBAC authorization mode..."
Invoke-AzCli "az keyvault create --name `"$keyVaultName`" --resource-group `"$resourceGroup`" --location `"$location`" --enable-rbac-authorization true --output none"

Write-Host "Verifying Azure Key Vault..."
az keyvault show `
  --name $keyVaultName `
  --query "{id:id, name:name, location:location, rbac:properties.enableRbacAuthorization}" `
  -o table

$vaultId = az keyvault show --name $keyVaultName --query id -o tsv


## STAGE 3 ##
Write-Host "Creating Service Principal and assigning Contributor at subscription scope..."
$spOutput = az ad sp create-for-rbac `
  --name $spName `
  --role "Contributor" `
  --scopes "/subscriptions/$subscriptionId" `
  -o json | ConvertFrom-Json

if ($LASTEXITCODE -ne 0) {
    throw "Failed to create Service Principal or assign Contributor role."
}

$appId        = $spOutput.appId
$clientSecret = $spOutput.password
$tenantId     = $spOutput.tenant

Write-Host "Service Principal Created - App ID: $(($appId -replace '^(.{4}).*(.{4})$', '$1****$2'))"
Write-Host "Tenant ID: $(($tenantId -replace '^(.{4}).*(.{4})$', '$1****$2'))"
Write-Host "Client Secret: [HIDDEN]"


## STAGE 4 ##
Write-Host "Granting current lab user permission to write secrets to the Key Vault..."

$currentUser = az account show --query user.name -o tsv

Invoke-AzCli "az role assignment create --assignee `"$currentUser`" --role `"Key Vault Secrets Officer`" --scope `"$vaultId`" --output none"

Write-Host "Waiting briefly for RBAC permissions to propagate..."
Start-Sleep -Seconds 20


## STAGE 5 ##
Write-Host "Storing Service Principal credentials in Key Vault..."

Invoke-AzCli "az keyvault secret set --vault-name `"$keyVaultName`" --name `"Terraform-Client-ID`" --value `"$appId`" --output none"
Invoke-AzCli "az keyvault secret set --vault-name `"$keyVaultName`" --name `"Terraform-Client-Secret`" --value `"$clientSecret`" --output none"
Invoke-AzCli "az keyvault secret set --vault-name `"$keyVaultName`" --name `"Terraform-Tenant-ID`" --value `"$tenantId`" --output none"
Invoke-AzCli "az keyvault secret set --vault-name `"$keyVaultName`" --name `"Terraform-Subscription-ID`" --value `"$subscriptionId`" --output none"

Write-Host "Listing stored secrets in Key Vault..."
az keyvault secret list `
  --vault-name $keyVaultName `
  --query "[].{name:name}" `
  -o table


## STAGE 6 ##
Write-Host "Granting Terraform Service Principal permission to read secrets from Key Vault..."

Invoke-AzCli "az role assignment create --assignee `"$appId`" --role `"Key Vault Secrets User`" --scope `"$vaultId`" --output none"

Write-Host "Setup Complete! Terraform service principal secrets are stored in Azure Key Vault using Azure RBAC authorization."
