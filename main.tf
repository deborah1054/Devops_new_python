# ----------------------------------------------
# 1. TERRAFORM AND PROVIDER CONFIGURATION
# ----------------------------------------------
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# ----------------------------------------------
# 2. UTILITY RESOURCE
# ----------------------------------------------
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
  numeric = true
}

# ----------------------------------------------
# 3. CORE AZURE INFRASTRUCTURE RESOURCES
# ----------------------------------------------

resource "azurerm_resource_group" "rg" {
  name     = "rg-python-project" # Renamed for Python
  location = var.location
}

resource "azurerm_container_registry" "acr" {
  name                = "pythonregistry${random_string.suffix.result}" # Renamed
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_service_plan" "app_plan" {
  name                = "plan-python-app" # Renamed
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "B1"
}

# ----------------------------------------------
# 4. WEB APP (THE CONTAINER HOST)
# ----------------------------------------------
resource "azurerm_linux_web_app" "web_app" {
  name                = "app-python-ci-cd-${random_string.suffix.result}" # Renamed
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.app_plan.id

  site_config {
    always_on  = false
    ftps_state = "Disabled"
  }

  app_settings = {
    "WEBSITES_PORT"                 = "3000" # Matches Dockerfile/app.py
    
    # Tells App Service what image to pull
    "DOCKER_CUSTOM_IMAGE_NAME"      = "${azurerm_container_registry.acr.login_server}/python-app:latest" # Renamed
    
    # Credentials for App Service to pull from our ACR
    "DOCKER_REGISTRY_SERVER_URL"    = "https://${azurerm_container_registry.acr.login_server}"
    "DOCKER_REGISTRY_SERVER_USERNAME" = azurerm_container_registry.acr.admin_username
    "DOCKER_REGISTRY_SERVER_PASSWORD" = azurerm_container_registry.acr.admin_password
  }
}

# ----------------------------------------------
# 5. OUTPUTS (FOR JENKINS)
# ----------------------------------------------

output "acr_login_server" {
  description = "The login server of the Azure Container Registry."
  value       = azurerm_container_registry.acr.login_server
}

output "web_app_name" {
  description = "The name of the Linux Web App."
  value       = azurerm_linux_web_app.web_app.name
}

output "resource_group_name" {
  description = "The name of the resource group."
  value       = azurerm_resource_group.rg.name
}