$templateFile='.\Template\azuredeploy.json'
$today= Get-Date -Format "yyyy-MM-dd-hh-mm-ss"
$DeploymentName='deployMLWorkspace-' + $today

$addressPrefixes = @("10.150.0.0/16")

$params= @(
"workspaceName=""$workspace_name""",
"location=""$location""",
#'sku="enterprise"',
'storageAccountOption="new"',
"storageAccountName=""$storage_account_name""",
'storageAccountType="Standard_LRS"',
'storageAccountBehindVNet="true"',
"storageAccountResourceGroupName=""$rg""",
'keyVaultOption="existing"',
"keyVaultName=""$env:keyvault_name""",
'keyVaultBehindVNet="true"',
"keyVaultResourceGroupName=""$rg""",
'applicationInsightsOption="new"',
"applicationInsightsName=""$application_insights_name""",
"applicationInsightsResourceGroupName=""$rg""",
'containerRegistryOption="new"',
"containerRegistryName=""$container_registry_name""",
'containerRegistrySku="Premium"',
"containerRegistryResourceGroupName=""$rg""",
'containerRegistryBehindVNet="true"',
'vnetOption="existing"',
'vnetName="hub"',
"vnetResourceGroupName=""$rg""",
"vnetLocation=""$location"""
#"addressPrefixes=""$addressPrefixes""",
'subnetOption="existing"',
'subnetName="training"',
'subnetPrefix="10.150.0.0/24"',
'adbWorkspace=""',
'confidential_data="true"',
'encryption_status="Enabled"',
"cmk_keyvault=$env:cmk_keyvault",
"resource_cmk_uri=$env:resource_cmk_uri",
'privateEndpointType="AutoApproval"'
)

az group deployment create `
--name $DeploymentName --resource-group $rg `
--template-file $templateFile `
--parameters $params


#az group create -n ngcml-dev5 -l eastus
#New-AzResourceGroupDeployment -ResourceGroupName "ngcml-dev5" -TemplateFile $templateFile -workspaceName "ngcml-dev5-wksp" -location "eastus" -Name $DeploymentName -containerRegistryOption "new" -containerRegistrySku "Premium" -storageAccountBehindVNet "true" -keyVaultBehindVNet "true" -containerRegistryBehindVNet "true" -vnetOption "new" -vnetName "vnet"

#az group create -n ngcml-dev6 -l eastus
# Create a workspace with private endpoint
#New-AzResourceGroupDeployment -ResourceGroupName "ngcml-dev6" -TemplateFile $templateFile -workspaceName "ngcml-dev6-wksp" -location "eastus" -Name $DeploymentName -privateEndpointType "AutoApproval"

az group create -n $rg -l $location
New-AzResourceGroupDeployment -ResourceGroupName $rg -TemplateFile $templateFile -workspaceName $workspace_name -location $location -Name $DeploymentName -privateEndpointType "AutoApproval" -vnetName "vnet" -subnetName "subnet"

az config set defaults.group=$rg

#Connect-AzAccount –Environment AzureUSGovernment
#Connect-AzAccount
#Set-AzContext -Subscription "$subscription_id"


New-AzResourceGroupDeployment -ResourceGroupName $rg -TemplateFile $templateFile -workspaceName $workspace_name `
-location $location -Name $DeploymentName -containerRegistryOption "new" -containerRegistrySku "Premium" `
-storageAccountBehindVNet "true" -keyVaultOption "existing" -keyVaultName $env:keyvault_name -keyVaultBehindVNet "true" `
-containerRegistryBehindVNet "true" -vnetOption "existing" `
-vnetName $vnet_name -subnetName $training_subnet_name -confidential_data "true" `
-encryption_status "Enabled" `
-cmk_keyvault $env:cmk_keyvault.Trim('"') `
-resource_cmk_uri $env:resource_cmk_uri.Trim('"') -privateEndpointType "AutoApproval"


