# Resource Group
output "resource_group" {
  value = "${azurerm_resource_group.rg.name}"
}

# App Service
output "compose_app_service_name" {
  value = "${azurerm_app_service.compose.name}"
}
output "compose_app_service_default_hostname" {
  value = "https://${azurerm_app_service.compose.default_site_hostname}"
}

output "dockerfile_app_service_name" {
  value = "${azurerm_app_service.dockerfile.name}"
}
output "dockerfile_app_service_default_hostname" {
  value = "https://${azurerm_app_service.dockerfile.default_site_hostname}"
}

output "keyvault_spn_application_id" {
  value = "${azuread_application.tesazure.application_id}"
}