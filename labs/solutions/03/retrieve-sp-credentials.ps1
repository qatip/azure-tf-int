param (
    [string]$KeyVaultName ,
    [string]$OutputFile = "./sp_credentials.env"
)

function Get-SecretValue {
    param ([string]$KeyVaultName, [string]$SecretName)
    $secureSecret = (Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretName).SecretValue
    return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureSecret))
}

## Stage 2 ##
# Connect to Azure account
Write-Host "Logging in to Azure..."
Connect-AzAccount

# Retrieve Service Principal credentials from Key Vault
Write-Host "Fetching Service Principal credentials from Key Vault..."
$clientId = Get-SecretValue -KeyVaultName $KeyVaultName -SecretName "Terraform-Client-ID"
$clientSecret = Get-SecretValue -KeyVaultName $KeyVaultName -SecretName "Terraform-Client-Secret"
$tenantId = Get-SecretValue -KeyVaultName $KeyVaultName -SecretName "Terraform-Tenant-ID"
$subscriptionId = Get-SecretValue -KeyVaultName $KeyVaultName -SecretName "Terraform-Subscription-ID"

## Stage 3 ##
# Set environment variables for Terraform
$env:ARM_CLIENT_ID = $clientId
$env:ARM_CLIENT_SECRET = $clientSecret
$env:ARM_TENANT_ID = $tenantId
$env:ARM_SUBSCRIPTION_ID = $subscriptionId

# Save credentials to a local `.env` file
Write-Host "Saving credentials to $OutputFile..."
@"
ARM_CLIENT_ID=$clientId
ARM_CLIENT_SECRET=$clientSecret
ARM_TENANT_ID=$tenantId
ARM_SUBSCRIPTION_ID=$subscriptionId
"@ | Set-Content -Path $OutputFile -NoNewline

Write-Host "Credentials saved successfully in both environment variables and a file!"
Write-Host "Use 'terraform init' and 'terraform apply' with these credentials."