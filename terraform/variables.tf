variable "resource_group_name" {
  type        = "string"
  description = "Name of the azure resource group."
  default     = "tesazure"
}

variable "resource_group_location" {
  type        = "string"
  description = "Location of the azure resource group."
  default     = "westus2"
}

variable "acr_sku" {
  type        = "string"
  description = "SKU for the Azure Container Registry"
  default     = "Basic"
}

variable "app_service_plan_sku_tier" {
  type        = "string"
  description = "SKU tier of the App Service Plan"
  default     = "Standard"                            # Basic | Standard | ...
}

variable "app_service_plan_sku_size" {
  type        = "string"
  description = "SKU size of the App Service Plan"
  default     = "S1"                               # B1 | S1 | ...
}