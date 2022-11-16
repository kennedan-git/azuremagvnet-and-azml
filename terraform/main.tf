data "azurerm_client_config" "current" {}

//Create Resource Group
resource "azurerm_resource_group" "aml_rg" {
  name                            = var.resource_group
  location                        = var.location
}

