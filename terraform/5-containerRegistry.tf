
// Container Registry - 1.1 - Create Azure Container Registry
resource "azurerm_container_registry" "aml_acr" {
    name                                        = "ngcmlkjtestacr${var.build_number}"
    resource_group_name                         = azurerm_resource_group.aml_rg.name
    location                                    = azurerm_resource_group.aml_rg.location
    sku                                         = "Premium"
    admin_enabled                               = true
    public_network_access_enabled               = false
  }

// Container Registry - 1.2 - Create Private DNS Zones for Azure Container Registry
resource "azurerm_private_dns_zone" "acr_zone" {
  name                                          = var.acr_zone
  resource_group_name                           = azurerm_resource_group.aml_rg.name
}

// Container Registry - 1.3 - Create Virtual Network Link to Private DNS Zone
resource "azurerm_private_dns_zone_virtual_network_link" "acr_zone_link" {
  name                                          = "${random_string.postfix.result}_link_kv"
  resource_group_name                           = azurerm_resource_group.aml_rg.name
  private_dns_zone_name                         = azurerm_private_dns_zone.acr_zone.name
  virtual_network_id                            = azurerm_virtual_network.aml_vnet.id
}

// Container Registry - 1.4 - Create Private Endpoint for Container Registry ("registry" sub-resource)
resource "azurerm_private_endpoint" "acr_pe" {
  name                                          = "${var.prefix}-acr-pe-${random_string.postfix.result}"
  location                                      = azurerm_resource_group.aml_rg.location
  resource_group_name                           = azurerm_resource_group.aml_rg.name
  subnet_id                                     = azurerm_subnet.aml_subnet.id

  private_service_connection {
    name                                        = "${var.prefix}-acr-psc-${random_string.postfix.result}"
    private_connection_resource_id              = azurerm_container_registry.aml_acr.id
    subresource_names                           = ["registry"]
    is_manual_connection                        = false
  }

  private_dns_zone_group {
    name                                        = "private-dns-zone-group-acr"
    private_dns_zone_ids                        = [azurerm_private_dns_zone.acr_zone.id]
  }
}