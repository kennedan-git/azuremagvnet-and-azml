
// Bastion Host - 1.1 - Create Public IP for Bastion Host
resource "azurerm_public_ip" "bastion_ip" {
  name                                    = "${var.prefix}-public-ip-bastion"
  location                                = azurerm_resource_group.aml_rg.location
  resource_group_name                     = azurerm_resource_group.aml_rg.name
  allocation_method                       = "Static"
  sku                                     = "Standard"
}

// Bastion Host - 1.2 - Create Bastion Host
resource "azurerm_bastion_host" "jumpbox_bastion" {
  name                                    = "${var.prefix}-bastion-host"
  location                                = azurerm_resource_group.aml_rg.location
  resource_group_name                     = azurerm_resource_group.aml_rg.name

  ip_configuration {
    name                                  = "configuration"
    subnet_id                             = azurerm_subnet.bastion_subnet.id
    public_ip_address_id                  = azurerm_public_ip.bastion_ip.id
  }
}