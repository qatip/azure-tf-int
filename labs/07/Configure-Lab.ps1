# Copyright (c) 2026 QA Michael Coulling-Green. All rights reserved.
#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$Location = 'denmarkeast',
    [ValidatePattern('^[a-z0-9]{3,24}$')]
    [string]$StorageAccountName = ('storageacct' + [guid]::NewGuid().ToString('N').Substring(0, 8)),
    [ValidatePattern('^[a-zA-Z0-9_.()-]{1,90}$')]
    [string]$ResourceGroupName = 'rg-tf-lab07',
    [hashtable]$AdditionalTags = @{},
    [switch]$RenewSas
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$settingsPath = Join-Path $PSScriptRoot 'terraform.tfvars.json'
$sasStart = [DateTime]::UtcNow.AddMinutes(-15).ToString('yyyy-MM-ddTHH:mm:ssZ')

if ($RenewSas) {
    if (-not (Test-Path -LiteralPath $settingsPath -PathType Leaf)) {
        throw 'Run Configure-Lab.ps1 without -RenewSas to create the lab settings first.'
    }
    $settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
    $settings | Add-Member -NotePropertyName 'sas_start_utc' -NotePropertyValue $sasStart -Force
    $settings | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $settingsPath -Encoding utf8
    Write-Host 'Updated only sas_start_utc. Run terraform plan and terraform apply, then retrieve the current URLs.'
    Write-Host ('New SAS expiry (UTC): ' + [DateTime]::UtcNow.AddHours(8).ToString('yyyy-MM-ddTHH:mm:ssZ'))
    return
}

if (Test-Path -LiteralPath $settingsPath) {
    throw 'terraform.tfvars.json already exists. Edit it to change settings, or use -RenewSas to renew the token window.'
}
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    throw 'Azure CLI was not found. Complete Lab 0 and open a new terminal.'
}
$accountJson = & az account show --output json
if ($LASTEXITCODE -ne 0) {
    throw 'Azure CLI has no usable current account. Run az login, select your training subscription, and retry.'
}
$account = ($accountJson -join [Environment]::NewLine) | ConvertFrom-Json
if (-not $account.id) {
    throw 'Azure CLI did not return a subscription ID.'
}
$owner = if ($env:USERNAME) { $env:USERNAME } elseif ($env:USER) { $env:USER } else { 'TrainingDelegate' }
$tags = @{ Owner = $owner }
foreach ($tagName in $AdditionalTags.Keys) {
    $tags[$tagName] = [string]$AdditionalTags[$tagName]
}
$settings = [ordered]@{
    subscription_id = [string]$account.id
    resource_group_name = $ResourceGroupName
    location = $Location
    storage_account_name = $StorageAccountName
    sas_start_utc = $sasStart
    additional_tags = $tags
}
$settings | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $settingsPath -Encoding utf8
Write-Host ('Subscription: ' + $account.name + ' (' + $account.id + ')')
Write-Host ('Resource group: ' + $ResourceGroupName)
Write-Host ('Storage account: ' + $StorageAccountName)
Write-Host ('Location: ' + $Location)
Write-Host ('Created: ' + $settingsPath)
Write-Host 'Check the generated settings before running Terraform.'
