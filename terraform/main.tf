provider "azurerm" {
  # Authenticates using Azure CLI
}
data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group_name}"
  location = "${var.resource_group_location}"
}

resource "random_integer" "ri" {
  min = 0
  max = 9999
}

resource "azurerm_app_service_plan" "default" {
  name                            = "flask-keyvault-test-appservice-${random_integer.ri.result}-plan"
  location                         = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  # Required for Linux
  kind                = "Linux"
  reserved = true

  sku {
    tier  = "${var.app_service_plan_sku_tier}"
    size = "${var.app_service_plan_sku_size}"
  }

  depends_on = [
    "azurerm_resource_group.rg"
  ]
}

resource "azurerm_key_vault" "vault" {
  name                                      = "flask-keyvault-test-${random_integer.ri.result}"
  location                                   = "${azurerm_resource_group.rg.location}"
  resource_group_name           = "${azurerm_resource_group.rg.name}"
  enabled_for_disk_encryption = true
  tenant_id                                = "${data.azurerm_client_config.current.tenant_id}"

  sku {
    name = "standard"
  }
}

#SPN for multi-container since MSI isn't supported yet
resource "azuread_application" "tesazure" {
  name                       = "tesazure"
}
resource "azuread_service_principal" "tesazure" {
  application_id = "${azuread_application.tesazure.application_id}"
}
resource "random_string" "spn_password" {
  length = 16
  special = true
}

resource "azuread_service_principal_password" "tesazure" {
  service_principal_id = "${azuread_service_principal.tesazure.id}"
  value                        = "${random_string.spn_password.result}"
  end_date_relative    = "26280h"
}

resource "azurerm_app_service" "compose" {
  name                             = "flask-keyvault-test-cp-${random_integer.ri.result}"
  location                         = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  app_service_plan_id    = "${azurerm_app_service_plan.default.id}"

  # Do not attach Storage by default
  app_settings {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = false
    KEYVAULT_URL = "${azurerm_key_vault.vault.vault_uri}"
    WEBSITE_HTTPLOGGING_RETENTION_DAYS = 3
    AZURE_CLIENT_ID =  "${azuread_application.tesazure.application_id}"
    AZURE_SECRET = "${random_string.spn_password.result}"
    AZURE_TENANT = "${data.azurerm_client_config.current.tenant_id}"
  }

  site_config {
    linux_fx_version = "COMPOSE|${base64encode(file("../docker-compose.yml"))}"
  }

  identity {
    type = "SystemAssigned"
  }

  depends_on = [
    "azurerm_app_service_plan.default",
    "azurerm_key_vault.vault"
  ]
}

resource "azurerm_app_service" "dockerfile" {
  name                             = "flask-keyvault-test-df-${random_integer.ri.result}"
  location                         = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  app_service_plan_id    = "${azurerm_app_service_plan.default.id}"

  # Do not attach Storage by default
  app_settings {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = false
    KEYVAULT_URL = "${azurerm_key_vault.vault.vault_uri}"
    WEBSITE_HTTPLOGGING_RETENTION_DAYS = 3
  }

  site_config {
    linux_fx_version = "DOCKER|mikaelsnavy/flask-keyvault-example",
    app_command_line= "python app.py"
  }

  identity {
    type = "SystemAssigned"
  }

  depends_on = [
    "azurerm_app_service_plan.default",
    "azurerm_key_vault.vault"
  ]
}

# Give MSI KeyVault access to the AppServices
resource "azurerm_key_vault_access_policy" "compose-msi" {
  key_vault_id          = "${azurerm_key_vault.vault.id}"

  tenant_id = "${azurerm_app_service.compose.identity.0.tenant_id}"
  object_id = "${azurerm_app_service.compose.identity.0.principal_id}"

  key_permissions = [
  ]

  secret_permissions = [
    "get",
    "list",
    "set"
  ]

  depends_on = [
    "azurerm_key_vault.vault",
    "azurerm_app_service.compose"
  ]
}
resource "azurerm_key_vault_access_policy" "dockerfile-msi" {
  key_vault_id          = "${azurerm_key_vault.vault.id}"

  tenant_id = "${azurerm_app_service.dockerfile.identity.0.tenant_id}"
  object_id = "${azurerm_app_service.dockerfile.identity.0.principal_id}"

  key_permissions = [
  ]

  secret_permissions = [
    "get",
    "list",
    "set"
  ]

  depends_on = [
    "azurerm_key_vault.vault",
    "azurerm_app_service.dockerfile"
  ]
}

# Give access to this script to pipulate a secret
resource "azurerm_key_vault_access_policy" "spn_id" {
  key_vault_id          = "${azurerm_key_vault.vault.id}"

  tenant_id           = "${data.azurerm_client_config.current.tenant_id}"
  object_id           = "${azuread_service_principal.tesazure.id}"


  key_permissions = [
  ]

  secret_permissions = [
    "get",
    "list",
    "set"
  ]

  depends_on = [
    "azurerm_key_vault.vault"
  ]
}

provider "azuread" {
  alias = "ad"
}

data "azuread_user" "cli_user" {
  provider = "azuread.ad"
  user_principal_name = "${var.az_cli_user}"
}

resource "azurerm_key_vault_access_policy" "client_id" {
  key_vault_id          = "${azurerm_key_vault.vault.id}"

  tenant_id           = "${data.azurerm_client_config.current.tenant_id}"
  object_id           = "${data.azuread_user.cli_user.id}"


  key_permissions = [
  ]

  secret_permissions = [
    "get",
    "list",
    "set",
    "delete"
  ]

  depends_on = [
    "azurerm_key_vault.vault"
  ]
}

resource "azurerm_key_vault_secret" "test" {
  name           = "test-secret"
  value            = "42"
  key_vault_id = "${azurerm_key_vault.vault.id}"

  depends_on = [
    "azurerm_key_vault.vault",
    "azurerm_key_vault_access_policy.spn_id",
    "azurerm_key_vault_access_policy.client_id"
  ]
} 

 
