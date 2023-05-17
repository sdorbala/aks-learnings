Param(
    [parameter(Mandatory=$false)]
    [string]$subscriptionId="02212f70-374b-4b54-8610-f68d316ed4f3",
    [parameter(Mandatory=$false)]
    [string]$resourceGroupName="scd-wus3-aks-rg",
    [parameter(Mandatory=$false)]
    [string]$resourceGroupLocation="West US 3",
    [parameter(Mandatory=$false)]
    [string]$clusterName="scd-aks-wus3-1",
    [parameter(Mandatory=$false)]
    [string]$vnetName="vnet-scd-aks-wus3-1",
    [parameter(Mandatory=$false)]
    [string]$vnetAddressSpace="10.10.0.0/16",
    [parameter(Mandatory=$false)]
    [string]$vnetSubnetName="snet-"+$clusterName,
    [parameter(Mandatory=$false)]
    [string]$vnetSubnetAddressSpace="10.10.0.0/22",
    [parameter(Mandatory=$false)]
    [string]$vnetAciSubnetName="snet-aci-"+$clusterName,
    [parameter(Mandatory=$false)]
    [string]$netAciSubnetAddressSpace="10.10.0.0/23",
    [parameter(Mandatory=$false)]
    [int16]$workerNodeCount=3,
    [parameter(Mandatory=$false)]
    [string]$kubernetesVersion="1.25.6",
    [parameter(Mandatory=$false)]
    [string] $containerRegistry="scdakslearnings",
    [parameter(Mandatory=$false)]
    [string] $logAnalyticsName="log-"+$clusterName,
    [parameter(Mandatory=$false)]
    [string] $logAnalyticsRetention=30,
    [parameter(Mandatory=$false)]
    [string] $vmsku="Standard_D4ds_v4"
)

# Set Azure Subscription
Write-Host "Setting Azure subscription to $subscriptionId"  -ForegroundColor Yellow
az account set --subscription=$subscriptionId

# Provider Registrations
# REGISTER THE AZURE POLICY PROVIDER
az provider register --namespace Microsoft.PolicyInsights

# REGISTER PROVIDERS FOR CONTAINER INSIGHTS
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.OperationsManagement
az provider register --namespace Microsoft.OperationalInsights

# REGISTER THE ENCRYPTION-AT-HOST FEATURE
az feature register --namespace Microsoft.Compute --name EncryptionAtHost

# CREATE THE RESOURCE GROUP
$resourceGroupExists = az group exists --name $resourceGroupName
if ($resourceGroupExists -eq "$false") {
    Write-Host "Creating resource group: "$resourceGroupName" in location: $resourceGroupLocation"
    az group create --name "$resourceGroupName" --location "$resourceGroupLocation"
} else {
    Write-Host "Resource group exists"
}

# Create Container Registry
az acr create --resource-group $resourceGroupName --name $containerRegistry --sku Basic

# Create Service Pricipal
az ad sp create-for-rbac --skip-assignment

# Create the vnet
$vnetExists = az network vnet list -g $resourceGroupName --query "[?name=='$VNET_NAME'].name" -o tsv
if ($vnetExists -ne $vnetName) {
    Write-Host "Creating vnet $vnetName in resourceGroup $resourceGroupName with address space $vnetAddressSpace"
    az network vnet create --resource-group $resourceGroupName `
     --name $vnetName `
     --address-prefix $vnetAddressSpace
} else {
    Write-Host "vnet $vnetName exists"
}

# Subnet for the cluster
$subnetExists = az network vnet subnet list -g $resourceGroupName --vnet-name $vnetName --query "[?name=='$vnetSubnetName'].name" -o tsv
if ($subnetExists -ne $vnetSubnetName) {
    Write-Host "Creating vnet subnet $vnetSubnetName in vnet $vnetName with address space $vnetSubnetAddressSpace"
    $vnetSubnetId = az network vnet subnet create --resource-group $resourceGroupName `
     --name $vnetSubnetName `
     --address-prefix $vnetSubnetAddressSpace
} else {
    Write-Host "vnet subnet $vnetSubnetName exists"
    $vnetSubnetId = az network vnet subnet list -g $resourceGroupName --vnet-name $vnetName --query "[?name=='$vnetSubnetName'].id" -o tsv
}

# Subnet for Azure Container Instances (ACI)
$subnetExists = az network vnet subnet list -g $resourceGroupName --vnet-name $vnetName --query "[?name=='$vnetAciSubnetName'].name" -o tsv
if ($subnetExists -ne $vnetAciSubnetName) {
    Write-Host "Creating vnet subnet $vnetAciSubnetName in vnet $vnetName with address space $vnetAciSubnetAddressSpace"
    $vnetAciSubnetId = az network vnet subnet create --resource-group $resourceGroupName `
     --name $vnetAciSubnetName `
     --address-prefix $vnetAciSubnetAddressSpace
} else {
    Write-Host "vnet subnet $vnetAciSubnetName exists"
    $vnetAciSubnetId = az network vnet subnet list -g $resourceGroupName --vnet-name $vnetName --query "[?name=='$vnetAciSubnetName'].id" -o tsv
}

# Log Analytics Workspace
$logAnalyticsWorkspaceExists = az monitor log-analytics workspace list --resource-group $resourceGroupName --query "[?name=='$logAnalyticsName'].name" -o tsv
if ($logAnalyticsWorkspaceExists -ne $logAnalyticsName) {
    az monitor log-analytics workspace create --resource-group $resourceGroupName `
    --workspace-name $logAnalyticsName `
    --location $resourceGroupLocation `
    --retention-time $logAnalyticsRetention
}

# Create AKS cluster
Write-Host "Creating AKS cluster $clusterName with resource group $resourceGroupName in region $resourceGroupLocation" -ForegroundColor Yellow
az aks create `
--resource-group=$resourceGroupName `
--name=$clusterName `
--node-count=$workerNodeCount `
--enable-managed-identity `
--output=jsonc `
--kubernetes-version=$kubernetesVersion `
--attach-acr=$containerRegistry `
--os-sku=AzureLinux `
--node-vm-size=$vmsku `
--node-osdisk-type Ephemeral `
--generate-ssh-keys

# Get credentials for newly created cluster
Write-Host "Getting credentials for cluster $clusterName" -ForegroundColor Yellow
az aks get-credentials `
--resource-group=$resourceGroupName `
--name=$clusterName

Write-Host "Successfully created cluster $clusterName with kubernetes version $kubernetesVersion and $workerNodeCount node(s)" -ForegroundColor Green
