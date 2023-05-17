# Lessons Learned During Setting Up AKS

## Provider Registrations
Make sure that you have the following providers registered on your subscription

- Microsoft.ContainerService
- Microsoft.OperationsManagement
- Microsoft.OperationalInsights

To check if these are already registered, use the following command

```
> az provider show -n Microsoft.ContainerService -o table
> az provider show -n Microsoft.OperationsManagement -o table
> az provider show -n Microsoft.OperationalInsights -o table
```

If these are not registered, you can register them with the following command

```
> az provider register --namespace Microsoft.OperationsManagement
```

## az cli extensions
Make sure that you have the following az cli extensions installed.

- aks-preview
- containerapp
- k8s-extension

To check what extensions are installed and general information about az cli, type `az --version` on powershell prompt. You should have see something like this

![image](images/az_version.png)

## Creating the aks cluster with Mariner image (now AzureLinux)
At the time of writing this doc, CBLMariner is now officially called as `AzureLinux` and it prompts you to use this name instead of `Mariner` or `CBLMariner`. These sku names will eventually be deprecated.

```
Write-Host "Creating AKS cluster $clusterName with resource group $resourceGroupName in region $resourceGroupLocaltion" -ForegroundColor Yellow
az aks create `
--resource-group=$resourceGroupName `
--name=$clusterName `
--node-count=$workerNodeCount `
--enable-managed-identity `
--output=jsonc `
--kubernetes-version=$kubernetesVersion `
--attach-acr=$containerRegistry `
--os-sku=AzureLinux `
--node-vm-size=$nodeSize `
--node-osdisk-type Ephemeral `
--generate-ssh-keys
```

The final argument `--generate-ssh-keys` is for the powershell (`kubectl`) to connect to the cluster. You can create ssh keys yourself and provide here or you can use this argument to generate them automatically for you. 

A bit about Ephemeral storage (see: https://learn.microsoft.com/en-us/azure/virtual-machines/ephemeral-os-disks)

This is a great guide: https://aztoso.com/aks/baseline-part-1/

Service Principal
ServicePrincipalName = 64f9c6e9-5119-4a4c-974f-de37017f3faa
UserName = 9cf2556b-6334-43e2-b651-234b07cd444e
Password = lVN8Q~akK1TNJv_nckaUth0M9phzRWxP.9OP3cQo

To switch between contexts we can use this command. For instance, this will set the context to local kubernetes environment provided by docker-desktop

```
> kubectl config use-context docker-desktop
```
