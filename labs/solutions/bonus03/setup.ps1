<#
End-to-end setup for Terraform on Azure via GitHub Actions (OIDC)
- Optional: creates Storage backend (RG + Storage + Container)
- Creates App Registration + Service Principal
- Assigns RBAC at subscription scope
- Creates federated credentials for:
    * branch:       repo:<owner>/<repo>:ref:refs/heads/<branch>
    * pull_request: repo:<owner>/<repo>:pull_request
#>

# ====================== EDIT THESE VALUES ======================

# Azure subscription
$SUBSCRIPTION_ID = "<sub_id>"

# Remote state backend (set $false to skip RG/Storage/Container creation)
$CREATE_STATE_BACKEND = $true
$STATE_RG      = "RG1"
$LOC           = "westeurope"
$STORAGE_NAME  = "tfstate$((Get-Random -Maximum 99999))"   # globally unique, lowercase
$CONTAINER     = "tfstate"
$STATE_KEY     = "tfstate"

# App / GitHub repo (MANDATORY)
$APP_NAME      = "gha-terraform$((Get-Random -Maximum 99999))"
$REPO          = "<owner/repo>"   # <-- owner/repo
$BRANCH        = "main"
#$ENVIRONMENT   = "prod"

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
Assert-NotEmpty -Name 'BRANCH'          -Value $BRANCH
Assert-NotEmpty -Name 'ENVIRONMENT'     -Value $ENVIRONMENT

# Build the federated credential subjects
$subjectBranch = "repo:${REPO}:ref:refs/heads/${BRANCH}"
#$subjectEnv    = "repo:${REPO}:environment:${ENVIRONMENT}"
$subjectPR     = "repo:${REPO}:pull_request"

Write-Host "Planned FC subjects:" -ForegroundColor Cyan
Write-Host "  Branch:       $subjectBranch"
#Write-Host "  Environment:  $subjectEnv"
Write-Host "  Pull Request: $subjectPR"

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

  # Create container with AAD; fall back to key if needed
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

# ---------- RBAC (subscription scope) ----------
$subscriptionScope = "/subscriptions/$SUBSCRIPTION_ID"
Write-Host "Assigning RBAC at $subscriptionScope (Contributor + Storage Blob Data Contributor) ..." -ForegroundColor Cyan
az role assignment create --assignee $APP_ID --role "Contributor" --scope $subscriptionScope | Out-Null
az role assignment create --assignee $APP_ID --role "Storage Blob Data Contributor" --scope $subscriptionScope | Out-Null
Write-Host "RBAC assignments complete." -ForegroundColor Green

# ---------- Federated Credentials (create or replace by name) ----------
function New-Or-Replace-FC {
  param([string]$AppId, [string]$Name, [string]$Subject)
  # If an FC with this name exists, delete it first (idempotent)
  try {
    $existing = az ad app federated-credential list --id $AppId | ConvertFrom-Json
    $toDel = $existing | Where-Object { $_.name -eq $Name }
    if ($toDel) {
      foreach ($fc in $toDel) {
        Write-Host "Deleting existing federated credential '$($fc.name)' (id=$($fc.id))..." -ForegroundColor DarkYellow
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

  Write-Host "Creating federated credential '$Name' with subject '$Subject' ..." -ForegroundColor Cyan
  az ad app federated-credential create --id $AppId --parameters "@$tmp" | Out-Null
  Remove-Item $tmp -Force
}

# 1) Branch-scoped
New-Or-Replace-FC -AppId $APP_ID -Name ("github-oidc-branch-$BRANCH") -Subject $subjectBranch
# 2) Environment-scoped
#New-Or-Replace-FC -AppId $APP_ID -Name ("github-oidc-env-$ENVIRONMENT") -Subject $subjectEnv
# 3) Pull Request–scoped
New-Or-Replace-FC -AppId $APP_ID -Name "github-oidc-pull-request" -Subject $subjectPR

# ---------- Verify FCs ----------
Write-Host "Verifying federated credentials for this app:" -ForegroundColor Cyan
az ad app federated-credential list --id $APP_ID -o table

Write-Host "`nFederated credentials created:" -ForegroundColor Yellow
Write-Host "  - Branch-based:       $subjectBranch"
#Write-Host "  - Environment-based:  $subjectEnv"
Write-Host "  - Pull-request based: $subjectPR"

# ---------- Output for GitHub ----------
$TENANT_ID = az account show --query tenantId -o tsv

Write-Host "`n===== Add these to your GitHub repo (Settings → Secrets and variables → Actions) =====" -ForegroundColor Yellow
Write-Host "Secrets:" -ForegroundColor Yellow
Write-Host "  AZURE_CLIENT_ID       = $APP_ID"
Write-Host "  AZURE_TENANT_ID       = $TENANT_ID"
Write-Host "  AZURE_SUBSCRIPTION_ID = $SUBSCRIPTION_ID"

if ($CREATE_STATE_BACKEND) {
  Write-Host "`nVariables:" -ForegroundColor Yellow
  Write-Host "  STATE_RG              = $STATE_RG"
  Write-Host "  STATE_STORAGE         = $STORAGE_NAME"
  Write-Host "  STATE_CONTAINER       = $CONTAINER"

  Write-Host "`nExample terraform init command (use in CI or locally):" -ForegroundColor Yellow
  Write-Host ("  terraform init -backend-config=`"resource_group_name={0}`" -backend-config=`"storage_account_name={1}`" -backend-config=`"container_name={2}`" -backend-config=`"key={3}`"" -f $STATE_RG, $STORAGE_NAME, $CONTAINER, $STATE_KEY)
}

Write-Host "`nAll done." -ForegroundColor Green
