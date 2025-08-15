# End-to-end setup for Terraform on Azure via GitHub Actions (OIDC)
# Supports multiple environments: dev, test, prod

# ====================== EDIT THESE VALUES ======================

# Azure subscription
$SUBSCRIPTION_ID = "<sub_id>"

# Remote state backend (set $false to skip RG/Storage/Container creation)
$CREATE_STATE_BACKEND = $true
$STATE_RG      = "RG1"
$LOC           = "westeurope"
$STORAGE_NAME  = "tfstate$((Get-Random -Maximum 99999))"   # globally unique, lowercase
$CONTAINER     = "tfstate"

# App / GitHub repo (MANDATORY)
$APP_NAME      = "gha-terraform$((Get-Random -Maximum 99999))"
$REPO          = "<owner/repo>"   # <-- owner/repo
$ENVIRONMENTS  = @("dev", "test", "prod")

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

# ---------- Validate inputs ----------
Assert-NotEmpty -Name 'SUBSCRIPTION_ID' -Value $SUBSCRIPTION_ID
Assert-NotEmpty -Name 'APP_NAME'        -Value $APP_NAME
Assert-NotEmpty -Name 'REPO'            -Value $REPO
Assert-RepoFormat -Repo $REPO

# ---------- Azure subscription context ----------
Write-Host "Setting subscription context..." -ForegroundColor Cyan
az account set --subscription $SUBSCRIPTION_ID
ThrowIfError "Failed to set subscription."

# ---------- Remote state backend (optional) ----------
if ($CREATE_STATE_BACKEND) {
  Write-Host "Ensuring remote state backend (RG/Storage/Container)..." -ForegroundColor Cyan

  az group create --name $STATE_RG --location $LOC | Out-Null
  ThrowIfError "Failed to create resource group."

  az storage account create `
    --resource-group $STATE_RG `
    --name $STORAGE_NAME `
    --location $LOC `
    --sku Standard_LRS `
    --encryption-services blob | Out-Null
  ThrowIfError "Failed to create storage account (ensure name is globally unique, lowercase)."

  az storage account update `
    --resource-group $STATE_RG `
    --name $STORAGE_NAME `
    --min-tls-version TLS1_2 | Out-Null

  az storage container create `
    --account-name $STORAGE_NAME `
    --name $CONTAINER `
    --auth-mode login | Out-Null
  if ($LASTEXITCODE -ne 0) {
    $saKey = az storage account keys list --resource-group $STATE_RG --account-name $STORAGE_NAME --query "[0].value" -o tsv
    az storage container create `
      --account-name $STORAGE_NAME `
      --name $CONTAINER `
      --account-key $saKey | Out-Null
  }
}

# ---------- App Registration + SP ----------
Write-Host "Creating App Registration: $APP_NAME" -ForegroundColor Cyan
$APP_ID = az ad app create --display-name $APP_NAME --query appId -o tsv
if (-not $APP_ID) { throw "Failed to create app registration." }
Write-Host "App created. AppId: $APP_ID" -ForegroundColor Green

Write-Host "Creating Service Principal for the app..." -ForegroundColor Cyan
az ad sp create --id $APP_ID | Out-Null

# ---------- RBAC ----------
$subscriptionScope = "/subscriptions/$SUBSCRIPTION_ID"
Write-Host "Assigning RBAC at $subscriptionScope..." -ForegroundColor Cyan
az role assignment create --assignee $APP_ID --role "Contributor" --scope $subscriptionScope | Out-Null
az role assignment create --assignee $APP_ID --role "Storage Blob Data Contributor" --scope $subscriptionScope | Out-Null
Write-Host "RBAC assignments complete." -ForegroundColor Green

# ---------- Federated Credentials ----------
function New-Or-Replace-FC {
  param([string]$AppId, [string]$Name, [string]$Subject)
  try {
    $existing = az ad app federated-credential list --id $AppId | ConvertFrom-Json
    $toDel = $existing | Where-Object { $_.name -eq $Name }
    if ($toDel) {
      foreach ($fc in $toDel) {
        Write-Host "Deleting existing federated credential '$($fc.name)'..." -ForegroundColor DarkYellow
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

  Write-Host "Creating federated credential '$Name' with subject '$Subject'..." -ForegroundColor Cyan
  az ad app federated-credential create --id $AppId --parameters "@$tmp" | Out-Null
  Remove-Item $tmp -Force
}

foreach ($ENV in $ENVIRONMENTS) {
  $STATE_KEY = "$ENV.tfstate"
  $BRANCH = $ENV
  $subjectBranch = "repo:${REPO}:ref:refs/heads/${BRANCH}"
  New-Or-Replace-FC -AppId $APP_ID -Name ("github-oidc-branch-${BRANCH}") -Subject $subjectBranch
  Write-Host "\nEnvironment: $ENV" -ForegroundColor Yellow
  Write-Host "  FC subject: $subjectBranch"
  Write-Host "  Backend key: $STATE_KEY"
}

# PR-wide FC
$subjectPR = "repo:${REPO}:pull_request"
New-Or-Replace-FC -AppId $APP_ID -Name "github-oidc-pull-request" -Subject $subjectPR

# ---------- Output for GitHub ----------
$TENANT_ID = az account show --query tenantId -o tsv
Write-Host "\n===== Add these to GitHub repo (Settings → Secrets and variables → Actions) =====" -ForegroundColor Yellow
Write-Host "Secrets:" -ForegroundColor Yellow
Write-Host "  AZURE_CLIENT_ID       = $APP_ID"
Write-Host "  AZURE_TENANT_ID       = $TENANT_ID"
Write-Host "  AZURE_SUBSCRIPTION_ID = $SUBSCRIPTION_ID"

if ($CREATE_STATE_BACKEND) {
  Write-Host "\nVariables:" -ForegroundColor Yellow
  Write-Host "  STATE_RG              = $STATE_RG"
  Write-Host "  STATE_STORAGE         = $STORAGE_NAME"
  Write-Host "  STATE_CONTAINER       = $CONTAINER"

  Write-Host "\nExample terraform init command:" -ForegroundColor Yellow
  Write-Host "  terraform init -backend-config=\"resource_group_name=$STATE_RG\" -backend-config=\"storage_account_name=$STORAGE_NAME\" -backend-config=\"container_name=$CONTAINER\" -backend-config=\"key=<env>.tfstate\""
}
