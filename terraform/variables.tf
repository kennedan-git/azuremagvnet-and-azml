# Configure the Microsoft Azure Provider
provider "azurerm" {
    features {}
            //subscription_id = var.subscription_id
            //client_id       = var.client_id
            //client_secret   = var.client_secret
            //tenant_id       = var.tenant_id           
            environment     = "usgovernment"  # Possible values are "public", "usgovernment", "german", and "china". Defaults to "public". #
}

variable "subscription_id" {
  description = "Enter Subscription ID for provisioning resources in Azure"
}

variable "client_id" {
  description = "Enter Client ID for Application created in Azure AD"
}

variable "client_secret" {
  description = "Enter Client secret for Application in Azure AD"
}

variable "tenant_id" {
  description = "Enter Tenant ID / Directory ID of your Azure AD. Run Get-AzureSubscription to know your Tenant ID"
}

variable "admin_password" {
  description = "Enter Administrator Password"
}

variable build_number {
  default = "9"
}

variable "resource_group" {
  default = "ngcml-dev-9"
}

variable "workspace_display_name" {
  default = "aml-terraform"
}

variable "location" {
  default = "US Gov Virginia"
}

variable "deploy_aks" {
  default = false
}

variable "jumpbox_username" {
  default = "azureuser"
}

//variable "jumpbox_password" {
//  default = "P@ssw0rd1"
//}

variable "prefix" {
  type = string
  default = "aml"
}

variable "kv_zone" {
  type = string
  default = "privatelink.vaultcore.usgovcloudapi.net"
}

variable "sa_zone_blob" {
  type = string
  default = "privatelink.blob.core.usgovcloudapi.net"
}

variable "sa_zone_file" {
  type = string
  default = "privatelink.file.core.usgovcloudapi.net"
}

variable "acr_zone" {
  type = string
  default = "privatelink.azurecr.us"
}

variable "ws_zone_api" {
  type = string
  default = "privatelink.api.ml.azure.us"
}

variable "ws_zone_notebooks" {
  type = string
  default = "privatelink.notebooks.usgovcloudapi.net"
}

resource "random_string" "postfix" {
  length = 6
  special = false
  upper = false
}