az aks create --resource-group ngcml-dev-55 --name kj-inf-k8s-cluster --node-count 3 --vnet-subnet-id "/subscriptions/8c98ce0c-4c4f-4ad4-8bd9-c026f79c0889/resourceGroups/ngcml-dev-55/providers/Microsoft.Network/virtualNetworks/aml-vnet-vm1mzh/subnets/aml-aks-subnet-vm1mzh" --load-balancer-sku standard --enable-private-cluster --generate-ssh-keys --network-plugin azure --service-cidr 10.0.4.0/24 --dns-service-ip 10.0.4.10 --docker-bridge-address 172.17.0.1/16