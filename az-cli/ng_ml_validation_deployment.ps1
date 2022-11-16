$delStartTime = $(get-date)
write-output "Deployment started at $delStartTime"

$login_environment = "AzureUSGovernment"
$subscription_id = "0678a88a-0c9d-4a4d-af2b-b52265d84789"
$subscription_name = "ML-validation"
$location = "usgovvirginia"

$build_number="3"
$random = Get-Random -Minimum 0 -Maximum 10000
$rg = "ngcml-dev" + "$build_number"
$storage_account_name = "ngcmlkjteststoracct" + "$build_number" #globally unique
$application_insights_name = "ngcmlkjtestai" + "$build_number"
$container_registry_name = "ngcmlkjtestacr" + "$build_number"
$keyvault_name = "ngcml-kv" + "$build_number" + "-$random" #globally unique
$vnet_name = "vnet"
$training_subnet_name = "subnet"
#$scoring_subnet_name = "scoring"
$workspace_name = "ngc-test-wkspace" + "$build_number"

$templateFile='.\Template\azuredeploy.json'
$today= Get-Date -Format "yyyy-MM-dd-hh-mm-ss"
$DeploymentName='deployMLWorkspace-' + $today

#az login
#Connect-AzAccount –Environment AzureUSGovernment
#Connect-AzAccount
#Set-AzContext -Subscription "$subscription_id"

$env:keyvault_name = "ngc-keyvault-$random"
az group create -n $rg -l $location
#New-AzResourceGroupDeployment -ResourceGroupName $rg -TemplateFile $templateFile -workspaceName $workspace_name `
#-location $location -Name $DeploymentName -containerRegistryOption "new" -containerRegistrySku "Premium" -containerRegistryName $container_registry_name `
#-storageAccountBehindVNet "true" -storageAccountName $storage_account_name -applicationInsightsName $application_insights_name `
#-keyVaultOption "new" -keyVaultName $env:keyvault_name -keyVaultBehindVNet "true" `
#-vnetOption "new" `
#-vnetName $vnet_name -subnetName $training_subnet_name `
#-privateEndpointType "AutoApproval"

az deployment group create `
  --name $DeploymentName `
  --resource-group $rg `
  --template-file $templateFile `
  --parameters workspaceName=$workspace_name location=$location containerRegistryOption="new" containerRegistrySku="Premium" `
  containerRegistryName=$container_registry_name storageAccountBehindVNet="true" storageAccountName=$storage_account_name `
  applicationInsightsName=$application_insights_name keyVaultOption="new" keyVaultName=$env:keyvault_name keyVaultBehindVNet="true" `
  vnetOption="new" vnetName=$vnet_name subnetName=$training_subnet_name privateEndpointType="AutoApproval"

#disable app insights public accesses
az monitor app-insights component update --app $application_insights_name -g $rg --ingestion-access Disabled
az monitor app-insights component update --app $application_insights_name -g $rg --query-access Disabled

az network vnet subnet update -g $rg --vnet-name $vnet_name -n $training_subnet_name --service-endpoints Microsoft.Storage Microsoft.KeyVault Microsoft.ContainerRegistry

#
# Enable private endpoint
#

$kv_id = az keyvault show -g $rg --name $env:keyvault_name --query id 
$cr_id = az acr show -g $rg --name $container_registry_name --query id 
$storage_id = az storage account show -g $rg --name $storage_account_name --query id 

#
# This section is based on: https://docs.microsoft.com/en-us/azure/key-vault/general/private-link-service?tabs=cli
#

#az provider register -n Microsoft.KeyVault                       # Register KeyVault as a provider
#az keyvault update -n $keyvault_name -g $rg --default-action deny # Turn on Key Vault Firewall
# Disable Virtual Network Policies
az network vnet subnet update --name $training_subnet_name --resource-group $rg --vnet-name $vnet_name --disable-private-endpoint-network-policies true

# Create a Private DNS Zones
az network private-dns zone create --resource-group $rg --name privatelink.vaultcore.usgovcloudapi.net
az network private-dns zone create --resource-group $rg --name privatelink.azurecr.us
az network private-dns zone create --resource-group $rg --name privatelink.blob.core.usgovcloudapi.net
az network private-dns zone create --resource-group $rg --name privatelink.file.core.usgovcloudapi.net

# Link the Private DNS Zone to the Virtual Network
az network private-dns link vnet create --resource-group $rg --virtual-network $vnet_name --zone-name privatelink.vaultcore.usgovcloudapi.net --name dnsZoneKVLink --registration-enabled false
az network private-dns link vnet create --resource-group $rg --virtual-network $vnet_name --zone-name privatelink.azurecr.us --name dnsZoneCRLink --registration-enabled false
az network private-dns link vnet create --resource-group $rg --virtual-network $vnet_name --zone-name privatelink.blob.core.usgovcloudapi.net --name dnsZoneBlobLink --registration-enabled false
az network private-dns link vnet create --resource-group $rg --virtual-network $vnet_name --zone-name privatelink.file.core.usgovcloudapi.net --name dnsZoneFileLink --registration-enabled false

#create private endpoint
az network private-endpoint create --resource-group $rg --vnet-name $vnet_name --subnet $training_subnet_name --name ngcml-kv-endpoint  --private-connection-resource-id $kv_id --group-id vault --connection-name pv-keyvault-connection --location $location
az network private-endpoint create --resource-group $rg --vnet-name $vnet_name --subnet $training_subnet_name --name ngcml-cr-endpoint  --private-connection-resource-id $cr_id --group-id registry --connection-name pv-registry-connection --location $location
az network private-endpoint create --resource-group $rg --vnet-name $vnet_name --subnet $training_subnet_name --name ngcml-blob-endpoint  --private-connection-resource-id $storage_id --group-id blob --connection-name pv-blob-connection --location $location
az network private-endpoint create --resource-group $rg --vnet-name $vnet_name --subnet $training_subnet_name --name ngcml-file-endpoint  --private-connection-resource-id $storage_id --group-id file --connection-name pv-file-connection --location $location

#show connection status
az network private-endpoint show --resource-group $rg --name ngcml-kv-endpoint
az network private-endpoint show --resource-group $rg --name ngcml-cr-endpoint
az network private-endpoint show --resource-group $rg --name ngcml-blob-endpoint
az network private-endpoint show --resource-group $rg --name ngcml-file-endpoint

##
## add private dns records
##

# Determine the Private Endpoint IP addresses
$kv_networkInterfaceId = az network private-endpoint show -g $rg -n ngcml-kv-endpoint --query networkInterfaces[].id -o tsv # look for the property networkInterfaces then id; the value must be placed on {PE NIC} below.
$kv_privateIP = az network nic show --ids $kv_networkInterfaceId --query ipConfigurations[].privateIpAddress -o tsv # look for the property ipConfigurations then privateIpAddress; the value must be placed on {NIC IP} below.

#cr has two IPs and two dns configs, one for data
$cr_fqdn0 = az network private-endpoint show -g $rg -n ngcml-cr-endpoint --query customDnsConfigs[0].fqdn -o tsv 
$cr_fqdn0 = $cr_fqdn0.Replace(".azurecr.us", "")
$cr_privateIP0 = az network private-endpoint show -g $rg -n ngcml-cr-endpoint --query customDnsConfigs[0].ipAddresses -o tsv 
$cr_fqdn1 = az network private-endpoint show -g $rg -n ngcml-cr-endpoint --query customDnsConfigs[1].fqdn -o tsv 
$cr_fqdn1 = $cr_fqdn1.Replace(".azurecr.us", "")
$cr_privateIP1 = az network private-endpoint show -g $rg -n ngcml-cr-endpoint --query customDnsConfigs[1].ipAddresses -o tsv 

$blob_networkInterfaceId = az network private-endpoint show -g $rg -n ngcml-blob-endpoint --query networkInterfaces[].id -o tsv 
$blob_privateIP = az network nic show --ids $blob_networkInterfaceId --query ipConfigurations[].privateIpAddress -o tsv 

$file_networkInterfaceId = az network private-endpoint show -g $rg -n ngcml-file-endpoint --query networkInterfaces[].id -o tsv 
$file_privateIP = az network nic show --ids $file_networkInterfaceId --query ipConfigurations[].privateIpAddress -o tsv 

# Create private zones 
# https://docs.microsoft.com/en-us/azure/dns/private-dns-getstarted-cli#create-an-additional-dns-record

az network private-dns zone list -g $rg
az network private-dns record-set a add-record -g $rg -z "privatelink.vaultcore.usgovcloudapi.net" -n $keyvault_name -a $kv_privateIP
az network private-dns record-set list -g $rg -z "privatelink.vaultcore.usgovcloudapi.net"

az network private-dns record-set a add-record -g $rg -z "privatelink.azurecr.us" -n $cr_fqdn0 -a $cr_privateIP0
az network private-dns record-set a add-record -g $rg -z "privatelink.azurecr.us" -n $cr_fqdn1 -a $cr_privateIP1
az network private-dns record-set list -g $rg -z "privatelink.azurecr.us"

az network private-dns record-set a add-record -g $rg -z "privatelink.blob.core.usgovcloudapi.net" -n "$storage_account_name" -a $blob_privateIP
az network private-dns record-set list -g $rg -z "privatelink.blob.core.usgovcloudapi.net"

az network private-dns record-set a add-record -g $rg -z "privatelink.file.core.usgovcloudapi.net" -n "$storage_account_name" -a $file_privateIP
az network private-dns record-set list -g $rg -z "privatelink.file.core.usgovcloudapi.net"


##
## Create a ML VM to access the vnet workspace
##
az vm create `
    --resource-group $rg `
    --name ml-vm `
    --image Win2019Datacenter `
    --public-ip-address '""'  `
    --vnet-name $vnet_name `
    --subnet $training_subnet_name `
    --admin-username mluser `
    --admin-password Qwerty123!@# 

##
## Create a Bastion Host and associated subnet 
##
az network public-ip create `
    --resource-group $rg `
    --name bastionIP `
    --sku Standard

az network vnet subnet create `
    --resource-group $rg `
    --name AzureBastionSubnet `
    --vnet-name $vnet_name `
    --address-prefixes 10.0.254.0/24

az network bastion create `
    --resource-group $rg `
    --name bastionHost `
    --public-ip-address bastionIP `
    --vnet-name $vnet_name `
    --location $location


$delElapsedTime = $(get-date) - $delStartTime
$delTotalTime = "{0:HH:mm:ss}" -f ([datetime]$delElapsedTime.Ticks)
Write-Output "Deployment of $workspace_name to $rg took $delTotalTime to run."
    