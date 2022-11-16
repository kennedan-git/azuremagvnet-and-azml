
// Storage Account - 1.1 - Create Storage Account with Private Endpoint for Blob and File
resource "azurerm_storage_account" "aml_sa" {
  name                                      = "ngcmlkjteststoracct${var.build_number}"    
  location                                  = azurerm_resource_group.aml_rg.location
  resource_group_name                       = azurerm_resource_group.aml_rg.name
  account_tier                              = "Standard"
  account_replication_type                  = "LRS"
}

// Storage Account - 1.2 - Creatte Virtual Network & Firewall configuration
resource "azurerm_storage_account_network_rules" "firewall_rules" {
  depends_on                                = [azurerm_machine_learning_workspace.aml_ws]            // Set network policies after Workspace has been created (will create File Share Datastore properly)
  resource_group_name                       = azurerm_resource_group.aml_rg.name
  storage_account_name                      = azurerm_storage_account.aml_sa.name
  default_action                            = "Deny"
  ip_rules                                  = []
  virtual_network_subnet_ids                = [azurerm_subnet.aml_subnet.id, azurerm_subnet.compute_subnet.id, azurerm_subnet.aks_subnet.id]
  bypass                                    = ["AzureServices"]  
}

// Storage Account - 1.3 -  Create Private DNS Zones for Azure Storage Account
resource "azurerm_private_dns_zone" "sa_zone_blob" {
  name                                      = var.sa_zone_blob
  resource_group_name                       = azurerm_resource_group.aml_rg.name
}

resource "azurerm_private_dns_zone" "sa_zone_file" {
  name                                      = var.sa_zone_file
  resource_group_name                       = azurerm_resource_group.aml_rg.name
}

// Storage Account - 1.4 -  Create Virtual Network Link to Private DNS Zone
resource "azurerm_private_dns_zone_virtual_network_link" "sa_zone_blob_link" {
  name                                      = "${random_string.postfix.result}_link_blob"
  resource_group_name                       = azurerm_resource_group.aml_rg.name
  private_dns_zone_name                     = azurerm_private_dns_zone.sa_zone_blob.name
  virtual_network_id                        = azurerm_virtual_network.aml_vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "sa_zone_file_link" {
  name                                      = "${random_string.postfix.result}_link_file"
  resource_group_name                       = azurerm_resource_group.aml_rg.name
  private_dns_zone_name                     = azurerm_private_dns_zone.sa_zone_file.name
  virtual_network_id                        = azurerm_virtual_network.aml_vnet.id
}

// Storage Account - 1.5 - Create Private Endpoint for Storage Account ("blob" & "file" sub-resource)
resource "azurerm_private_endpoint" "sa_pe_blob" {
  name                                      = "${var.prefix}-sa-pe-blob-${random_string.postfix.result}"
  location                                  = azurerm_resource_group.aml_rg.location
  resource_group_name                       = azurerm_resource_group.aml_rg.name
  subnet_id                                 = azurerm_subnet.aml_subnet.id

  private_service_connection {
    name                                    = "${var.prefix}-sa-psc-blob-${random_string.postfix.result}"
    private_connection_resource_id          = azurerm_storage_account.aml_sa.id
    subresource_names                       = ["blob"]
    is_manual_connection                    = false
  }

  private_dns_zone_group {
    name                                    = "private-dns-zone-group-blob"
    private_dns_zone_ids                    = [azurerm_private_dns_zone.sa_zone_blob.id]
  }
}

resource "azurerm_private_endpoint" "sa_pe_file" {
  name                                      = "${var.prefix}-sa-pe-file-${random_string.postfix.result}"
  location                                  = azurerm_resource_group.aml_rg.location
  resource_group_name                       = azurerm_resource_group.aml_rg.name
  subnet_id                                 = azurerm_subnet.aml_subnet.id

  private_service_connection {
    name                                    = "${var.prefix}-sa-psc-file-${random_string.postfix.result}"
    private_connection_resource_id          = azurerm_storage_account.aml_sa.id
    subresource_names                       = ["file"]
    is_manual_connection                    = false
  }

  private_dns_zone_group {
    name                                    = "private-dns-zone-group-file"
    private_dns_zone_ids                    = [azurerm_private_dns_zone.sa_zone_file.id]
  }
}