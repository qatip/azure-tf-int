<#
End-to-end setup for Terraform on Azure via GitHub Actions (OIDC)
- Optional: creates Storage backend (RG + Storage + Container)
- Creates App Registration + Service Principal
- Assigns RBAC at subscription scope
- Creates federated credentials for:
    * single mode:    repo:<owner>/<repo>:ref:refs/heads/<branch>
    * multi mode:     repo:<owner>/<repo>:ref:refs/heads/dev|test|prod
    * optional:       repo:<owner>/<repo>:pull_request
    * optional main:  repo:<owner>/<repo>:ref:refs/heads/main   (for running destroy from main)
#>

# ====================== EDIT THESE VALUES ======================

# Mode: "single" or "multi"
$MODE = "multi"

# Azure subscription
$SUBSCRIPTION_ID = "<sub_id>"

# Remote state backend (set $false to skip RG/Storage/Container creation)
$CREATE_STATE_BACKEND = $true
$STATE_RG      = "state-rg"
$LOC           = "westeurope"
$STORAGE_NAME  = "tfstate$((Get-Random -Maximum 99999))"
$CONTAINER     = "tfstate"

# App / GitHub repo (MANDATORY)
$APP_NAME      = "gha-terraform$((Get-Random -Maximum 99999))"
$REPO          = "qatip/terraform-az-galab"   # <-- owner/repo

# Single-mode branch
$BRANCH        = "main"

# Multi-mode environment branches
$ENVIRONMENTS  = @("dev", "test", "prod")

# Add a federated credential for 'main' so you can run workflows (e.g., destroy) from main
$ADD_MAIN_DESTROY_FC = $true

# ===============================================================

function ThrowIfError($msg) { if ($LASTEXITCODE -ne 0) { throw $msg } }

function Assert-NotEmpty {
  param([string]$Name, [string]$Value)
  if ([string]::IsNullOrWhiteSpace($Value)) { throw "$Name is empty. Set it in the config block." }
}

function Assert-RepoFormat {
  param([string]$Repo)
  if ($Repo -notmatch '^[^/\s]+/[^/\s]+$') { throw "REPO must be in 'owner/repo' format. Current: '$Repo'." }
}

Assert-NotEmpty -Name 'SUBSCRIPTION_ID' -Value $SUBSCRIPTION_ID
Assert-NotEmpty -Name 'APP_NAME'        -Value $APP_NAME
Assert-NotEmpty -Name 'REPO'            -Value $REPO
Assert-RepoFormat -Repo $REPO

Write-Host "Setting Azure subscription context..." -ForegroundColor Cyan
az account set --subscription $SUBSCRIPTION_ID
ThrowIfError "Failed to set subscription."

if ($CREATE_STATE_BACKEND) {
  Write-Host "Creating storage backend (RG, Storage Account, Container)..." -ForegroundColor Cyan

  az group create --name $STATE_RG --location $LOC | Out-Null
  az storage account create `
    --resource-group $STATE_RG `
    --name $STORAGE_NAME `
    --location $LOC `
    --sku Standard_LRS `
    --encryption-services blob | Out-Null

  az storage container create `
    --account-name $STORAGE_NAME `
    --name $CONTAINER `
    --auth-mode login | Out-Null
}

Write-Host "Creating App Registration: $APP_NAME" -ForegroundColor Cyan
$APP_ID = az ad app create --display-name $APP_NAME --query appId -o tsv
ThrowIfError "App registration failed."

az ad sp create --id $APP_ID | Out-Null

Write-Host "Assigning Contributor and Storage roles..." -ForegroundColor Cyan
$subscriptionScope = "/subscriptions/$SUBSCRIPTION_ID"
az role assignment create --assignee $APP_ID --role "Contributor" --scope $subscriptionScope | Out-Null
az role assignment create --assignee $APP_ID --role "Storage Blob Data Contributor" --scope $subscriptionScope | Out-Null

function New-Or-Replace-FC {
  param([string]$AppId, [string]$Name, [string]$Subject)
  try {
    $existing = az ad app federated-credential list --id $AppId | ConvertFrom-Json
    $toDel = $existing | Where-Object { $_.name -eq $Name }
    if ($toDel) {
      foreach ($fc in $toDel) {
        Write-Host "Deleting existing federated credential '$($fc.name)'" -ForegroundColor DarkYellow
        az ad app federated-credential delete --id $AppId --federated-credential-id $fc.id | Out-Null
      }
    }
  } catch {}

  $payload = @{
    name      = $Name
    issuer    = "https://token.actions.githubusercontent.com"
    subject   = $Subject
    audiences = @("api://AzureADTokenExchange")
  }

  $tmp = New-TemporaryFile
  $payload | ConvertTo-Json -Depth 5 | Set-Content -Path $tmp -Encoding utf8
  az ad app federated-credential create --id $AppId --parameters "@$tmp" | Out-Null
  Remove-Item $tmp -Force
}

if ($MODE -eq "single") {
  # one FC for the single branch (e.g., main)
  $subjectBranch = "repo:${REPO}:ref:refs/heads/${BRANCH}"
  New-Or-Replace-FC -AppId $APP_ID -Name "github-oidc-${BRANCH}" -Subject $subjectBranch
  Write-Host "Created federated credential for single branch: $subjectBranch" -ForegroundColor Green
}
elseif ($MODE -eq "multi") {
  # FC per environment branch
  foreach ($env in $ENVIRONMENTS) {
    $subject = "repo:${REPO}:ref:refs/heads/${env}"
    New-Or-Replace-FC -AppId $APP_ID -Name "github-oidc-${env}" -Subject $subject
    Write-Host "Created federated credential for: $subject" -ForegroundColor Green
  }

  # PR-wide FC so plans work on PRs into env branches
  $subjectPR = "repo:${REPO}:pull_request"
  New-Or-Replace-FC -AppId $APP_ID -Name "github-oidc-pull-request" -Subject $subjectPR
  Write-Host "Created federated credential for PRs: $subjectPR" -ForegroundColor Green
}

# Optional: add FC for 'main' so you can run destroy (or other workflows) from main
if ($ADD_MAIN_DESTROY_FC) {
  $subjectMain = "repo:${REPO}:ref:refs/heads/main"
  New-Or-Replace-FC -AppId $APP_ID -Name "github-oidc-main" -Subject $subjectMain
  Write-Host "Created federated credential for main: $subjectMain" -ForegroundColor Green
}

$TENANT_ID = az account show --query tenantId -o tsv
Write-Host "`n===== Add these to GitHub repo (Settings → Secrets and variables → Actions) =====" -ForegroundColor Yellow
Write-Host "Secrets:"
Write-Host "  AZURE_CLIENT_ID       = $APP_ID"
Write-Host "  AZURE_TENANT_ID       = $TENANT_ID"
Write-Host "  AZURE_SUBSCRIPTION_ID = $SUBSCRIPTION_ID"

if ($CREATE_STATE_BACKEND) {
  Write-Host "`nVariables:"
  Write-Host "  STATE_RG              = $STATE_RG"
  Write-Host "  STATE_STORAGE         = $STORAGE_NAME"
  Write-Host "  STATE_CONTAINER       = $CONTAINER"
}
