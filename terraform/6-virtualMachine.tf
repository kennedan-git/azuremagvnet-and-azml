// Virtual Machine - 1.1 - Create Public IP and NIC card for Virtual Machine
resource "azurerm_public_ip" "jumpbox_public_ip" {
  name                                           = "jumpbox-public-ip"
  location                                       = azurerm_resource_group.aml_rg.location
  resource_group_name                            = azurerm_resource_group.aml_rg.name
  allocation_method                              = "Static"
}

resource "azurerm_network_interface" "jumpbox_nic" {
  name                                           = "jumpbox-nic"
  location                                       = azurerm_resource_group.aml_rg.location
  resource_group_name                            = azurerm_resource_group.aml_rg.name

  ip_configuration {
    name                                         = "configuration"
    private_ip_address_allocation                = "Dynamic"
    subnet_id                                    = azurerm_subnet.aml_subnet.id
    public_ip_address_id                         = azurerm_public_ip.jumpbox_public_ip.id
  }
}

// Virtual Machine - 1.2 - Create NSG and link it to Virtual Machine's NIC card
resource "azurerm_network_security_group" "jumpbox_nsg" {
  name                                           = "jumpbox-nsg"
  location                                       = azurerm_resource_group.aml_rg.location
  resource_group_name                            = azurerm_resource_group.aml_rg.name

  security_rule {
    name                                         = "RDP"
    priority                                     = 1010
    direction                                    = "Inbound"
    access                                       = "Allow"
    protocol                                     = "Tcp"
    source_port_range                            = "*"
    destination_port_range                       = 3389
    source_address_prefix                        = "*"
    destination_address_prefix                   = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "jumpbox_nsg_association" {
  network_interface_id                           = azurerm_network_interface.jumpbox_nic.id
  network_security_group_id                      = azurerm_network_security_group.jumpbox_nsg.id
}

// Virtual Machine - 1.3 - Create Virtual Machine
resource "azurerm_virtual_machine" "jumpbox" {
  name                                           = "jumpbox"
  location                                       = azurerm_resource_group.aml_rg.location
  resource_group_name                            = azurerm_resource_group.aml_rg.name
  network_interface_ids                          = [azurerm_network_interface.jumpbox_nic.id]
  vm_size                                        = "Standard_DS3_v2"

  delete_os_disk_on_termination                  = true
  delete_data_disks_on_termination               = true

  storage_image_reference {
    publisher                                    = "microsoft-dsvm"
    offer                                        = "dsvm-win-2019"
    sku                                          = "server-2019"
    version                                      = "latest"
  }

  os_profile {
    computer_name                                = "jumpbox"
    admin_username                               = var.jumpbox_username
    admin_password                               = var.admin_password
  }

  os_profile_windows_config {
    provision_vm_agent                           = true
    enable_automatic_upgrades                    = true
  }

  identity {
    type                                         = "SystemAssigned"
  }

  storage_os_disk {
    name                                         = "jumpbox-osdisk"
    caching                                      = "ReadWrite"
    create_option                                = "FromImage"
    managed_disk_type                            = "StandardSSD_LRS"
  }
}