az vm create `
    --resource-group $rg `
    --name ml-vm `
    --image Win2019Datacenter `
    --public-ip-address '""'  `
    --vnet-name $vnet_name `
    --subnet $training_subnet_name `
    --admin-username mluser `
    --admin-password Qwerty123!@# 

    az vm create `
    --resource-group $rg `
    --name ml-vm7 `
    --image Win2019Datacenter `
    --public-ip-address ml-vm7-publicip  `
    --vnet-name $vnet_name `
    --subnet $training_subnet_name `
    --admin-username mluser `
    --admin-password Qwerty123!@# 