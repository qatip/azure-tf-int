# =================== EDIT THESE VALUES ===================
$SUBSCRIPTION_ID          = ""                        # leave "" to use current az account
$REPO                     = "qatip/tf-az-ga-envs"        # MANDATORY owner/repo
$ENVIRONMENTS             = @("dev","test","prod")
$APP_NAME                 = "gh-oidc-qatip-tf-az-ga-envs" # make it unique per repo
$SUBSCRIPTION_ROLES       = @("Contributor")          # initial coarse role at subscription

# Remote state backend
$CREATE_STATE_BACKEND     = $true
$STATE_RG                 = "rg-tfstate"
$LOCATION                 = "westeurope"
$STATE_STORAGE_ACCOUNT    = ""                        # "" = auto-generate (3-24 lowercase letters/numbers)
$STATE_CONTAINER          = "tfstate"

# Also add a federated credential for pull_request? (usually false)
$ADD_PULL_REQUEST_SUBJECT = $false

# Skip confirmation prompts?
$FORCE                    = $true
# ================= END OF EDITABLE VALUES =================

# ----------------- Helpers -----------------
function Write-Info { param($m) Write-Host "[INFO ] $m" -ForegroundColor Cyan }
function Write-Ok   { param($m) Write-Host "[ OK  ] $m" -ForegroundColor Green }
function Write-Err  { param($m) Write-Host "[ERR  ] $m" -ForegroundColor Red }

function Ensure-Az(){ try{ az account show --only-show-errors | Out-Null } catch{ throw "Not logged in. Run: az login" } }
function J([string]$s){ if($s){ $s | ConvertFrom-Json } }
function LowerAlnum([string]$s){ ($s.ToLower() -replace '[^a-z0-9]','') }
function GenStorage([string]$seed){
  $seed = LowerAlnum ($seed -replace '/','')
  if($seed.Length -gt 16){ $seed = $seed.Substring(0,16) }
  $rand = -join ((48..57 + 97..122) | Get-Random -Count 6 | ForEach-Object { [char]$_ })
  $name = "tf$seed$rand"
  if($name.Length -gt 24){ $name = $name.Substring(0,24) }
  return $name
}

function Ensure-App([string]$name){
  $e = J (az ad app list --display-name $name --query "[0]" --only-show-errors)
  if($null -eq $e){
    Write-Info "Creating App Registration: $name"
    J (az ad app create --display-name $name --sign-in-audience AzureADMyOrg --only-show-errors)
  } else { Write-Info "Reusing App Registration: $name"; $e }
}

function Ensure-SP([string]$appId){
  $sp = J (az ad sp list --filter "appId eq '$appId'" --query "[0]" --only-show-errors)
  if($null -eq $sp){
    Write-Info "Creating Service Principal for AppId: $appId"
    J (az ad sp create --id $appId --only-show-errors)
  } else { Write-Info "Reusing Service Principal"; $sp }
}

# Use --assignee for LIST (compat); use object-id for CREATE
function Ensure-Role([string]$spObj,[string]$scope,[string]$role){
  $has = J (az role assignment list --assignee $spObj --role "$role" --scope $scope --query "[0]" --only-show-errors)
  if($has){ Write-Info "RBAC exists: $role @ $scope"; return }
  Write-Info "Assigning RBAC: $role @ $scope"
  az role assignment create --assignee-object-id $spObj --assignee-principal-type ServicePrincipal --role "$role" --scope $scope --only-show-errors | Out-Null
  if($LASTEXITCODE -ne 0){ Write-Err "RBAC assign failed: $role @ $scope"; exit 1 }
  Write-Ok "Assigned: $role"
}

# Quiet SA existence check (no 404 noise)
function Get-StorageAccountOrNull([string]$rg,[string]$name){
  $json = az storage account list --resource-group $rg --query "[?name=='$name'] | [0]" --only-show-errors 2>$null
  if(-not $json){ return $null }
  return $json | ConvertFrom-Json
}

function Ensure-RG([string]$rg,[string]$loc){
  if((az group exists --name $rg --only-show-errors) -eq "true"){
    Write-Info "Resource Group exists: $rg"
  } else {
    Write-Info "Creating Resource Group: $rg ($loc)"
    az group create --name $rg --location $loc --only-show-errors | Out-Null
    Write-Ok "Created RG: $rg"
  }
}

function Ensure-SA([string]$rg,[string]$name,[string]$loc){
  $sa = Get-StorageAccountOrNull $rg $name
  if($sa){ Write-Info "Storage Account exists: $name"; return $sa }
  Write-Info "Creating Storage Account: $name ($loc)"
  az storage account create --name $name --resource-group $rg --location $loc --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2 --allow-blob-public-access false --https-only true --only-show-errors | Out-Null
  az storage account blob-service-properties update --account-name $name --resource-group $rg --enable-versioning true --only-show-errors | Out-Null
  az storage account blob-service-properties update --account-name $name --resource-group $rg --delete-retention-days 7 --enable-delete-retention true --only-show-errors | Out-Null
  $sa = Get-StorageAccountOrNull $rg $name
  Write-Ok "Created Storage Account: $name"
  return $sa
}

function Ensure-Container([string]$account,[string]$container){
  $exists = J (az storage container exists --name $container --account-name $account --auth-mode login --only-show-errors)
  if($exists -and $exists.exists -eq $true){
    Write-Info "Blob Container exists: $container"
  } else {
    Write-Info "Creating Blob Container: $container"
    az storage container create --name $container --account-name $account --auth-mode login --public-access off --only-show-errors | Out-Null
    Write-Ok "Created Container: $container"
  }
}

# Create or fix a federated credential (uses temp JSON to avoid quoting issues)
function Ensure-FedCred([string]$appId,[string]$name,[string]$subject){
  $issuer = "https://token.actions.githubusercontent.com"
  $aud    = "api://AzureADTokenExchange"
  $existing = J (az ad app federated-credential list --id $appId --only-show-errors)
  $byName = $existing | Where-Object { $_.name -eq $name }
  if($byName){
    if($byName.subject -eq $subject -and $byName.issuer -eq $issuer){
      Write-Info "Federated credential exists: $name ($subject)"; return
    } else {
      Write-Info "Replacing federated credential with corrected subject: $name"
      az ad app federated-credential delete --id $appId --federated-credential-id $byName.id --only-show-errors | Out-Null
    }
  }
  $tmp = New-TemporaryFile
  @{
    name        = $name
    issuer      = $issuer
    subject     = $subject
    audiences   = @($aud)
    description = "GitHub OIDC for $subject"
  } | ConvertTo-Json -Compress | Out-File -FilePath $tmp -Encoding utf8 -NoNewline
  Write-Info "Creating federated credential: $name ($subject)"
  az ad app federated-credential create --id $appId --parameters "@$tmp" --only-show-errors | Out-Null
  Remove-Item $tmp -ErrorAction SilentlyContinue
  if($LASTEXITCODE -ne 0){ Write-Err "Federated credential create failed: $name"; exit 1 }
  Write-Ok "Created federated credential: $name"
}

# ----------------- Start -----------------
Ensure-Az
$acct = J (az account show --only-show-errors)
$TENANT_ID = $acct.tenantId
if([string]::IsNullOrWhiteSpace($SUBSCRIPTION_ID)){ $SUBSCRIPTION_ID = $acct.id }

if(-not $REPO -or $REPO -notmatch "^[^/]+/[^/]+$"){ throw "REPO must be 'owner/repo' (e.g., org/repo)." }

if([string]::IsNullOrWhiteSpace($STATE_STORAGE_ACCOUNT)){ $STATE_STORAGE_ACCOUNT = GenStorage $REPO }
if($STATE_STORAGE_ACCOUNT -notmatch "^[a-z0-9]{3,24}$"){ throw "STATE_STORAGE_ACCOUNT must be 3-24 lowercase letters/numbers." }
$STATE_CONTAINER = LowerAlnum $STATE_CONTAINER
if(-not $STATE_CONTAINER){ $STATE_CONTAINER = "tfstate" }

if(-not $FORCE){
  Write-Host "Repo: $REPO" -ForegroundColor Yellow
  Write-Host "Envs: $($ENVIRONMENTS -join ', ')" -ForegroundColor Yellow
  Write-Host "Sub:  $SUBSCRIPTION_ID" -ForegroundColor Yellow
  Write-Host "Tenant: $TENANT_ID" -ForegroundColor Yellow
  Write-Host "App:  $APP_NAME" -ForegroundColor Yellow
  Write-Host "Create backend: $CREATE_STATE_BACKEND" -ForegroundColor Yellow
  if($CREATE_STATE_BACKEND){ Write-Host "RG: $STATE_RG  Loc: $LOCATION  SA: $STATE_STORAGE_ACCOUNT  Container: $STATE_CONTAINER" -ForegroundColor Yellow }
  if((Read-Host "Proceed? (y/N)") -notin @("y","Y","yes","YES")){ Write-Err "Aborted."; exit 1 }
}

az account set --subscription $SUBSCRIPTION_ID --only-show-errors | Out-Null

# Identity
$app = Ensure-App $APP_NAME
$APP_ID = $app.appId
$sp  = Ensure-SP $APP_ID
$SP_OBJECT_ID = $sp.id

# Subscription-level RBAC
$subScope = "/subscriptions/$SUBSCRIPTION_ID"
foreach($role in $SUBSCRIPTION_ROLES){ Ensure-Role $SP_OBJECT_ID $subScope $role }

# Backend
if($CREATE_STATE_BACKEND){
  Ensure-RG $STATE_RG $LOCATION
  $sa = Ensure-SA $STATE_RG $STATE_STORAGE_ACCOUNT $LOCATION
  Ensure-Container $STATE_STORAGE_ACCOUNT $STATE_CONTAINER
  Ensure-Role $SP_OBJECT_ID $sa.id "Storage Blob Data Contributor"
}

# Federated credentials (Environment subjects)
foreach($environment in $ENVIRONMENTS){
  $name    = "github-env-$environment"
  $subject = "repo:$($REPO):environment:$($environment)"
  Ensure-FedCred $APP_ID $name $subject
}

# Print the subjects
$ENVIRONMENTS | ForEach-Object {
  Write-Host ("  repo:{0}:environment:{1}" -f $REPO, $_)
}

if($ADD_PULL_REQUEST_SUBJECT){
  Ensure-FedCred $APP_ID "github-pull_request" "repo:$REPO:pull_request"
}

Write-Host ""
Write-Ok "Setup complete."
Write-Host "Add to EACH GitHub Environment (dev/test/prod):" -ForegroundColor Yellow
Write-Host "  Secrets:"
Write-Host "    AZURE_CLIENT_ID       = $APP_ID"
Write-Host "    AZURE_TENANT_ID       = $TENANT_ID"
Write-Host "    AZURE_SUBSCRIPTION_ID = $SUBSCRIPTION_ID"
if($CREATE_STATE_BACKEND){
  Write-Host "  Variables:"
  Write-Host "    STATE_RG        = $STATE_RG"
  Write-Host "    STATE_STORAGE   = $STATE_STORAGE_ACCOUNT"
  Write-Host "    STATE_CONTAINER = $STATE_CONTAINER"
}
Write-Host "`nOIDC subjects configured:" -ForegroundColor Yellow
$ENVIRONMENTS | ForEach-Object { Write-Host "  repo:$REPO:environment:$_" }
