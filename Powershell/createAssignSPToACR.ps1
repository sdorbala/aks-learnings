Param(
    [parameter(Mandatory=$false)]
    [string]$resourceGroupName="scd-wus3-aks-rg",
    [parameter(Mandatory=$false)]
    [string]$resourceGroupLocation="West US 3",
    [parameter(Mandatory=$false)]
    [string] $containerRegistry="scdakslearnings"
)

$acrId = az acr show --resource-group $resourceGroupName --name $containerRegistry --query "id" --output tsv

$servicePrincipalName = New-Guid

$password = az ad sp create-for-rbac --name $servicePrincipalName --scopes $acrId --role acrpull --query "password" --output tsv
$username = az ad sp list --display-name $servicePrincipalName --query "[].appId" --output tsv

Write-Host "ServicePrincipalName = $servicePrincipalName, UserName = $username, Password = $password"
