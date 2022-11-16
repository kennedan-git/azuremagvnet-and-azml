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
