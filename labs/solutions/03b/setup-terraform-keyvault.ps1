$ErrorActionPreference = "Stop"

$resourceGroup  = "RG1"
$location       = "West Europe"
$keyVaultName   = "<your vault name>"
$subscriptionId = "<your subscription id>"
$spName         = "terraform-sp-<unique suffix>"

function Invoke-AzCli {
    param([Parameter(Mandatory = $true)][string]$Command)

    Invoke-Expression $Command

    if ($LASTEXITCODE -ne 0) {
        throw "Azure CLI command failed: $Command"
    }
}

function Ensure-RoleAssignment {
    param(
        [string]$ObjectId,
        [string]$PrincipalType,
        [string]$Role,
        [string]$Scope
    )

    $existing = az role assignment list `
        --assignee $ObjectId `
        --role "$Role" `
        --scope "$Scope" `
        --query "[0].id" `
        -o tsv

    if ([string]::IsNullOrWhiteSpace($existing)) {
        Write-Host "Creating role assignment: $Role"

        Invoke-AzCli "az role assignment create --assignee-object-id `"$ObjectId`" --assignee-principal-type `"$PrincipalType`" --role `"$Role`" --scope `"$Scope`" --output none"
    }
    else {
        Write-Host "Role assignment already exists: $Role"
    }
}

Write-Host "Logging into Azure..."
az login | Out-Null

Write-Host "Selecting subscription..."
Invoke-AzCli "az account set --subscription `"$subscriptionId`""

Write-Host "Checking Resource Group..."
$rgExists = az group exists --name $resourceGroup

if ($rgExists -eq "true") {
    Write-Host "Resource Group already exists."
}
else {
    Write-Host "Creating Resource Group..."
    Invoke-AzCli "az group create --name `"$resourceGroup`" --location `"$location`" --output none"
}

Write-Host "Checking Key Vault..."
$existingVaultName = az keyvault list `
    --resource-group $resourceGroup `
    --query "[?name=='$keyVaultName'].name | [0]" `
    -o tsv

if ([string]::IsNullOrWhiteSpace($existingVaultName)) {
    Write-Host "Creating Azure Key Vault in RBAC authorization mode..."

    Invoke-AzCli "az keyvault create --name `"$keyVaultName`" --resource-group `"$resourceGroup`" --location `"$location`" --enable-rbac-authorization true --output none"
}
else {
    Write-Host "Key Vault already exists."

    $rbacEnabled = az keyvault show `
        --name $keyVaultName `
        --resource-group $resourceGroup `
        --query "properties.enableRbacAuthorization" `
        -o tsv

    if ($rbacEnabled -ne "true") {
        Write-Host "Enabling RBAC authorization on existing Key Vault..."
        Invoke-AzCli "az keyvault update --name `"$keyVaultName`" --resource-group `"$resourceGroup`" --enable-rbac-authorization true --output none"
    }
}

$vaultId = az keyvault show `
    --name $keyVaultName `
    --resource-group $resourceGroup `
    --query id `
    -o tsv

Write-Host "Checking Service Principal..."
$existingSp = az ad sp list `
    --display-name $spName `
    --query "[0]" `
    -o json | ConvertFrom-Json

$tenantId = az account show --query tenantId -o tsv

if ($null -eq $existingSp) {
    Write-Host "Creating Service Principal..."

    $spOutput = az ad sp create-for-rbac `
        --name $spName `
        --role "Contributor" `
        --scopes "/subscriptions/$subscriptionId" `
        -o json | ConvertFrom-Json

    $appId        = $spOutput.appId
    $clientSecret = $spOutput.password
}
else {
    $appId = $existingSp.appId

    Write-Host "Service Principal already exists."
    Write-Host "Resetting client secret..."

    $clientSecret = az ad app credential reset `
        --id $appId `
        --query password `
        -o tsv
}

$terraformSpObjectId = az ad sp show --id $appId --query id -o tsv

Write-Host "Service Principal App ID: $(($appId -replace '^(.{4}).*(.{4})$', '$1****$2'))"
Write-Host "Tenant ID: $(($tenantId -replace '^(.{4}).*(.{4})$', '$1****$2'))"
Write-Host "Client Secret: [HIDDEN]"

Write-Host "Granting current lab user permission to write secrets to Key Vault..."
$currentUserObjectId = az ad signed-in-user show --query id -o tsv

Ensure-RoleAssignment `
    -ObjectId $currentUserObjectId `
    -PrincipalType "User" `
    -Role "Key Vault Secrets Officer" `
    -Scope $vaultId

Write-Host "Granting Terraform Service Principal permission to read secrets from Key Vault..."

Ensure-RoleAssignment `
    -ObjectId $terraformSpObjectId `
    -PrincipalType "ServicePrincipal" `
    -Role "Key Vault Secrets User" `
    -Scope $vaultId

Write-Host "Waiting for RBAC permissions to propagate..."
Start-Sleep -Seconds 60

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

$configFile = Join-Path $PWD.Path "terraform-keyvault-lab.config.json"

$config = [ordered]@{
    resourceGroup  = $resourceGroup
    location       = $location
    keyVaultName   = $keyVaultName
    subscriptionId = $subscriptionId
    spName         = $spName
    appId          = $appId
    tenantId       = $tenantId
}

$config | ConvertTo-Json | Set-Content -Path $configFile -Encoding UTF8

Write-Host "Saved lab configuration to: $configFile"
Write-Host "Setup Complete! Terraform service principal secrets are stored in Azure Key Vault using Azure RBAC authorization."