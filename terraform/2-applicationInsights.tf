// Application Insights - 1.1 - Create Application Insights for Azure Machine Learning

resource "azurerm_application_insights" "aml_ai" {
  name                               = "ngcmlkjtestai-${var.build_number}"
  location                           = azurerm_resource_group.aml_rg.location
  resource_group_name                = azurerm_resource_group.aml_rg.name
  application_type                   = "web"
  }

// Application Insights - 1.2 - Disable "ingession-access" and "query-access" from Public Networks on Application Insights
// For this to succeed you need to install Application Insights CLI Extension (az extension add -n application-insights)
 
resource "null_resource" "disable_ai_public_access" {
  
  depends_on                        = [azurerm_application_insights.aml_ai]
  
  provisioner "local-exec" {
    command="az monitor app-insights component update --app ${azurerm_application_insights.aml_ai.name} -g ${azurerm_resource_group.aml_rg.name} --ingestion-access Disabled"
  }

  provisioner "local-exec" {
    command="az monitor app-insights component update --app ${azurerm_application_insights.aml_ai.name} -g ${azurerm_resource_group.aml_rg.name} --query-access Disabled"
  }
 
}
