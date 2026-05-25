$ErrorActionPreference = "Stop"

## SECTION 1 - Read local lab configuration
# This file is created by setup-terraform-keyvault.ps1.

$configFile = Join-Path $PWD.Path "terraform-keyvault-lab.config.json"
$envFile    = Join-Path $PWD.Path "sp_credentials.env"

if (-not (Test-Path $configFile)) {
    throw "Config file not found: $configFile. Run cleanup from the same folder as the setup script, or recreate the values manually."
}

$config = Get-Content -Path $configFile -Raw | ConvertFrom-Json

$resourceGroup  = $config.resourceGroup
$location       = $config.location
$keyVaultName   = $config.keyVaultName
$subscriptionId = $config.subscriptionId
$spName         = $config.spName
$appId          = $config.appId


## SECTION 2 - Define helper function

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


## SECTION 3 - Authenticate and select subscription

Write-Host "Logging into Azure..."
az login | Out-Null

Write-Host "Selecting subscription..."
Invoke-AzCli "az account set --subscription `"$subscriptionId`""


## SECTION 4 - Delete and purge the Key Vault
# Purge is submitted with --no-wait so the script can continue.

Write-Host "Checking Key Vault..."

$rgExists = az group exists --name $resourceGroup

if ($rgExists -eq "true") {
    $existingVaultName = az keyvault list `
        --resource-group $resourceGroup `
        --query "[?name=='$keyVaultName'].name | [0]" `
        -o tsv
}
else {
    $existingVaultName = $null
}

if (-not [string]::IsNullOrWhiteSpace($existingVaultName)) {
    Write-Host "Deleting Key Vault: $keyVaultName"
    Invoke-AzCli "az keyvault delete --name `"$keyVaultName`" --resource-group `"$resourceGroup`" --output none"

    Write-Host "Waiting for Key Vault to enter deleted state..."

    $deletedVault = $null
    for ($i = 1; $i -le 24; $i++) {
        Start-Sleep -Seconds 5

        $deletedVault = az keyvault list-deleted `
            --query "[?name=='$keyVaultName'].name | [0]" `
            -o tsv

        if (-not [string]::IsNullOrWhiteSpace($deletedVault)) {
            break
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($deletedVault)) {
        Write-Host "Purging deleted Key Vault..."
        Invoke-AzCli "az keyvault purge --name `"$keyVaultName`" --location `"$location`" --no-wait --output none"
        Write-Host "Key Vault purge submitted."
    }
    else {
        Write-Host "Key Vault did not appear in deleted vaults within the wait period. Skipping purge attempt."
    }
}
else {
    Write-Host "Key Vault not found as an active vault. Checking deleted vaults..."

    $deletedVault = az keyvault list-deleted `
        --query "[?name=='$keyVaultName'].name | [0]" `
        -o tsv

    if (-not [string]::IsNullOrWhiteSpace($deletedVault)) {
        Write-Host "Purging previously deleted Key Vault..."
        Invoke-AzCli "az keyvault purge --name `"$keyVaultName`" --location `"$location`" --no-wait --output none"
        Write-Host "Key Vault purge submitted."
    }
    else {
        Write-Host "No active or deleted Key Vault found. Skipping."
    }
}


## SECTION 5 - Delete the Service Principal and App Registration

Write-Host "Checking for Service Principal..."

$existingSp = az ad sp list `
    --display-name $spName `
    --query "[?displayName=='$spName'] | [0]" `
    -o json | ConvertFrom-Json

if ($null -ne $existingSp) {
    Write-Host "Deleting Service Principal and App Registration: $spName"
    Invoke-AzCli "az ad app delete --id `"$appId`""
}
else {
    Write-Host "Service Principal not found. Skipping."
}


## SECTION 6 - Delete the resource group

Write-Host "Checking Resource Group..."
$rgExists = az group exists --name $resourceGroup

if ($rgExists -eq "true") {
    Write-Host "Deleting Resource Group: $resourceGroup"
    Invoke-AzCli "az group delete --name `"$resourceGroup`" --yes --no-wait"
    Write-Host "Resource Group deletion submitted."
}
else {
    Write-Host "Resource Group not found. Skipping."
}


## SECTION 7 - Remove local files

if (Test-Path $configFile) {
    Write-Host "Removing local configuration file..."
    Remove-Item $configFile -Force
}

if (Test-Path $envFile) {
    Write-Host "Removing local credential file..."
    Remove-Item $envFile -Force
}
else {
    Write-Host "Credential file not found. Skipping."
}


## SECTION 8 - Confirm cleanup completion

Write-Host "Cleanup Complete."
Write-Host "Some Azure delete/purge operations may continue asynchronously for several minutes."
