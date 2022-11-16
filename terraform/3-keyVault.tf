
// Key Vault - 1.1 - Create Azure Key Vault with Private Endpoint

resource "azurerm_key_vault" "aml_kv" {
  name                                      = "ngcml-kv-${var.build_number}-${random_string.postfix.result}"
  location                                  = azurerm_resource_group.aml_rg.location
  resource_group_name                       = azurerm_resource_group.aml_rg.name
  tenant_id                                 = data.azurerm_client_config.current.tenant_id
  sku_name                                  = "standard"

  network_acls {
    default_action                          = "Deny"
    ip_rules                                = []
    virtual_network_subnet_ids              = [azurerm_subnet.aml_subnet.id, azurerm_subnet.compute_subnet.id, azurerm_subnet.aks_subnet.id]
    bypass                                  = "AzureServices"
  }
}

// Key Vault - 1.2 - Create Private DNS Zones for Azure Key Vault
resource "azurerm_private_dns_zone" "kv_zone" {
  name                                      = var.kv_zone
  resource_group_name                       = azurerm_resource_group.aml_rg.name
}

// Key Vault - 1.3 - Create Virtual Network Link to Private DNS Zone
resource "azurerm_private_dns_zone_virtual_network_link" "kv_zone_link" {
  name                                      = "${random_string.postfix.result}_link_kv"
  resource_group_name                       = azurerm_resource_group.aml_rg.name
  private_dns_zone_name                     = azurerm_private_dns_zone.kv_zone.name
  virtual_network_id                        = azurerm_virtual_network.aml_vnet.id
}

// Key Vault - 1.4 - Create Private Endpoint for Key Vault ("vault" sub-resource)
resource "azurerm_private_endpoint" "kv_pe" {
  name                                      = "${var.prefix}-kv-pe-${random_string.postfix.result}"
  location                                  = azurerm_resource_group.aml_rg.location
  resource_group_name                       = azurerm_resource_group.aml_rg.name
  subnet_id                                 = azurerm_subnet.aml_subnet.id

  private_service_connection {
    name                                    = "${var.prefix}-kv-psc-${random_string.postfix.result}"
    private_connection_resource_id          = azurerm_key_vault.aml_kv.id
    subresource_names                       = ["vault"]
    is_manual_connection                    = false
  }

  private_dns_zone_group {
    name                                    = "private-dns-zone-group-kv"
    private_dns_zone_ids                    = [azurerm_private_dns_zone.kv_zone.id]
  }
}