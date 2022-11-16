
// Machine Learning - 1.1 - Create Azure Machine Learning Workspace 

resource "azurerm_machine_learning_workspace" "aml_ws" {
  name                                                 = "ngc-test-wkspace-${var.build_number}"
  friendly_name                                        = var.workspace_display_name
  location                                             = azurerm_resource_group.aml_rg.location
  resource_group_name                                  = azurerm_resource_group.aml_rg.name
  application_insights_id                              = azurerm_application_insights.aml_ai.id
  key_vault_id                                         = azurerm_key_vault.aml_kv.id
  storage_account_id                                   = azurerm_storage_account.aml_sa.id
  container_registry_id                                = azurerm_container_registry.aml_acr.id

  identity {
    type                                               = "SystemAssigned"
  }
}

// Machine Learning - 1.2 - Create Compute Resources in Azure Machine Learning Workspace 
// For this to succeed you need to install Azure Machine Learning CLI Extension (az extension add -n azure-cli-ml)

resource "null_resource" "compute_resouces" {
  
  depends_on                                           = [azurerm_machine_learning_workspace.aml_ws]

  provisioner "local-exec" {
    command="az ml computetarget create amlcompute --max-nodes 1 --min-nodes 0 --name cpu-cluster --vm-size Standard_DS3_v2 --idle-seconds-before-scaledown 600 --assign-identity [system] --vnet-name ${azurerm_subnet.compute_subnet.virtual_network_name} --subnet-name ${azurerm_subnet.compute_subnet.name} --vnet-resourcegroup-name ${azurerm_subnet.compute_subnet.resource_group_name} --resource-group ${azurerm_machine_learning_workspace.aml_ws.resource_group_name} --workspace-name ${azurerm_machine_learning_workspace.aml_ws.name}"
  }

  provisioner "local-exec" {
    command="az ml computetarget create computeinstance --name ci-${random_string.postfix.result}-test --vm-size Standard_DS3_v2 --vnet-name ${azurerm_subnet.compute_subnet.virtual_network_name} --subnet-name ${azurerm_subnet.compute_subnet.name} --vnet-resourcegroup-name ${azurerm_subnet.compute_subnet.resource_group_name} --resource-group ${azurerm_machine_learning_workspace.aml_ws.resource_group_name} --workspace-name ${azurerm_machine_learning_workspace.aml_ws.name}"
  }
 
}

// Machine Learning - 1.3 - Create Private DNS Zones for Azure Machine Learning Workspace
resource "azurerm_private_dns_zone" "ws_zone_api" {
  name                                                 = var.ws_zone_api
  resource_group_name                                  = azurerm_resource_group.aml_rg.name
}

resource "azurerm_private_dns_zone" "ws_zone_notebooks" {
  name                                                 = var.ws_zone_notebooks
  resource_group_name                                  = azurerm_resource_group.aml_rg.name
}

// Machine Learning - 1.4 - Create Virtual Network Link to Private DNS Zones
resource "azurerm_private_dns_zone_virtual_network_link" "ws_zone_api_link" {
  name                                                 = "${random_string.postfix.result}_link_api"
  resource_group_name                                  = azurerm_resource_group.aml_rg.name
  private_dns_zone_name                                = azurerm_private_dns_zone.ws_zone_api.name
  virtual_network_id                                   = azurerm_virtual_network.aml_vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "ws_zone_notebooks_link" {
  name                                                 = "${random_string.postfix.result}_link_notebooks"
  resource_group_name                                  = azurerm_resource_group.aml_rg.name
  private_dns_zone_name                                = azurerm_private_dns_zone.ws_zone_notebooks.name
  virtual_network_id                                   = azurerm_virtual_network.aml_vnet.id
}

// Machine Learning - 1.5 - Create Private Endpoint for Azure Machine Leaning Workspace sub-resource
resource "azurerm_private_endpoint" "ws_pe" {
  name                                                 = "${var.prefix}-ws-pe-${random_string.postfix.result}"
  location                                             = azurerm_resource_group.aml_rg.location
  resource_group_name                                  = azurerm_resource_group.aml_rg.name
  subnet_id                                            = azurerm_subnet.aml_subnet.id

  private_service_connection {
    name                                               = "${var.prefix}-ws-psc-${random_string.postfix.result}"
    private_connection_resource_id                     = azurerm_machine_learning_workspace.aml_ws.id
    subresource_names                                  = ["amlworkspace"]
    is_manual_connection                               = false
  }

  private_dns_zone_group {
    name                                               = "private-dns-zone-group-ws"
    private_dns_zone_ids                               = [azurerm_private_dns_zone.ws_zone_api.id, azurerm_private_dns_zone.ws_zone_notebooks.id]
  }

  # Add Private Link after we configured the workspace and attached AKS
  //depends_on = [null_resource.compute_resouces]                           // azurerm_kubernetes_cluster.aml_aks
}
