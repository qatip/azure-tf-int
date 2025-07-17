# Variables
$ResourceGroupName = "RG1"
$Location = "westeurope"
$VMName = "VM1"
$Image = "Ubuntu2404"
$VMSize = "Standard_B2S"
$AdminUsername = "azureuser"
#$Tags = @{
#    environment = "dev"
#    project = "myproject"
#}

# Create Resource Group
Write-Host "Creating Resource Group: $ResourceGroupName..."
az group create --name $ResourceGroupName --location $Location

# Create VM
Write-Host "Creating Virtual Machine: $VMName..."
$VM = az vm create `
    --resource-group $ResourceGroupName `
    --name $VMName `
    --image $Image `
    --size $VMSize `
    --admin-username $AdminUsername `
    --generate-ssh-keys `
    --public-ip-sku Standard `
    --query "{name: name, publicIP: publicIpAddress}" -o json

# Check if VM was created successfully
if ($VM -ne $null) {
    $VMName = $VM | ConvertFrom-Json | Select-Object -ExpandProperty name
    $VMIP = $VM | ConvertFrom-Json | Select-Object -ExpandProperty publicIP
    Write-Host "Virtual Machine $VMName is accessible at IP: $VMIP"
} else {
    Write-Host "Error: VM creation failed."
}
