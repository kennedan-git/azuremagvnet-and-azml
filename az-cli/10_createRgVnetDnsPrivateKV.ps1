az group create -n $rg -l $location

#create ml VNet and Subnets
az network vnet create -g $rg -n $vnet_name --address-prefix 10.0.0.0/16 --subnet-name $training_subnet_name --subnet-prefix 10.0.0.0/24
az network vnet subnet update -g $rg --vnet-name $vnet_name -n $training_subnet_name --service-endpoints Microsoft.Storage Microsoft.KeyVault Microsoft.ContainerRegistry
#az network vnet subnet create -g $rg --vnet-name $vnet_name -n $scoring_subnet_name --address-prefixes 10.0.1.0/24
#az network vnet subnet update -g $rg --vnet-name $vnet_name -n $scoring_subnet_name --service-endpoints Microsoft.Storage Microsoft.KeyVault Microsoft.ContainerRegistry

#create NSG and attach to subnet
az network nsg create -n ws1103nsg -g $rg
az network vnet subnet update -g $rg --vnet-name $vnet_name -n $training_subnet_name --network-security-group ws1103nsg
#az network vnet subnet update -g $rg --vnet-name $vnet_name -n $scoring_subnet_name --network-security-group ws1103nsg

#create kevault and key
az keyvault create -l $location -n $keyvault_name -g $rg
az keyvault key create -n ws1103key --vault-name $keyvault_name
$kv_id = az keyvault show -g $rg --name $keyvault_name --query id 
$env:keyvault_name = $keyvault_name
$env:cmk_keyvault = $kv_id
$env:resource_cmk_uri = az keyvault key show --name "ws1103key" --vault-name $keyvault_name --query key.kid 

#
# This section is based on: https://docs.microsoft.com/en-us/azure/key-vault/general/private-link-service?tabs=cli
#

az provider register -n Microsoft.KeyVault                       # Register KeyVault as a provider
#az keyvault update -n $keyvault_name -g $rg --default-action deny # Turn on Key Vault Firewall
# Disable Virtual Network Policies
az network vnet subnet update --name $training_subnet_name --resource-group $rg --vnet-name $vnet_name --disable-private-endpoint-network-policies true
# Create a Private DNS Zone
az network private-dns zone create --resource-group $rg --name privatelink.vaultcore.azure.net
# Link the Private DNS Zone to the Virtual Network
az network private-dns link vnet create --resource-group $rg --virtual-network $vnet_name --zone-name privatelink.vaultcore.azure.net --name dnsZoneLink --registration-enabled true

az network private-endpoint create --resource-group $rg --vnet-name $vnet_name --subnet $training_subnet_name --name ngcml-kv-endpoint  --private-connection-resource-id $kv_id --group-id vault --connection-name pv-keyvault-connection --location $location

#show connection status
az network private-endpoint show --resource-group $rg --name ngcml-kv-endpoint

#add private dns records
# Determine the Private Endpoint IP address
$kv_networkInterfaceId = az network private-endpoint show -g $rg -n ngcml-kv-endpoint --query networkInterfaces[].id -o tsv # look for the property networkInterfaces then id; the value must be placed on {PE NIC} below.
$kv_privateIP = az network nic show --ids $kv_networkInterfaceId --query ipConfigurations[].privateIpAddress -o tsv                      # look for the property ipConfigurations then privateIpAddress; the value must be placed on {NIC IP} below.

# https://docs.microsoft.com/en-us/azure/dns/private-dns-getstarted-cli#create-an-additional-dns-record
az network private-dns zone list -g $rg
az network private-dns record-set a add-record -g $rg -z "privatelink.vaultcore.azure.net" -n $keyvault_name -a $kv_privateIP
az network private-dns record-set list -g $rg -z "privatelink.vaultcore.azure.net"
