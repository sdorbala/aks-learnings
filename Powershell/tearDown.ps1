
Param(
    [parameter(Mandatory=$false)]
    [string]$subscriptionId="02212f70-374b-4b54-8610-f68d316ed4f3",
    [parameter(Mandatory=$false)]
    [string]$resourceGroupName="scd-wus3-aks-rg",
    [parameter(Mandatory=$false)]
    [string]$resourceGroupLocaltion="West US 3",
    [parameter(Mandatory=$false)]
    [string]$clusterName="scd-aks-wus3-1",
    [parameter(Mandatory=$false)]
    [int16]$workerNodeCount=3,
    [parameter(Mandatory=$false)]
    [string]$kubernetesVersion="1.25.6",
    [parameter(Mandatory=$false)]
    [string] $containerRegistry="scdakslearnings",
    [parameter(Mandatory=$false)]
    [string] $vmsku="Standard_DS3_V2"
)

# Set Azure Subscription
Write-Host "Setting Azure subscription to $subscriptionId"  -ForegroundColor Yellow
az account set --subscription=$subscriptionId

# Delete ACR
Write-Host "Deleting ACR $containerRegistry..."  -ForegroundColor Yellow
az acr delete --name $containerRegistry --resource-group $resourceGroupName --yes

# Delete AKS Cluster
Write-Host "Deleting AKS cluster $clusterName..."  -ForegroundColor Yellow
az aks delete --name $clusterName --resource-group $resourceGroupName --yes

# Delete resource group
Write-Host "Deleting resource group $resourceGroupName..."  -ForegroundColor Yellow
az group delete --name $resourceGroupName

Write-Host "Successfully deleted resources" -ForegroundColor Green
