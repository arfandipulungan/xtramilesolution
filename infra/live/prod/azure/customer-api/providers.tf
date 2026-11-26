terraform {
  required_version = ">= 1.10"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
  }
}

# Credentials come from the pipeline's OIDC login (ARM_USE_OIDC, ARM_CLIENT_ID,
# ARM_TENANT_ID, ARM_SUBSCRIPTION_ID); nothing is stored here.
provider "azurerm" {
  features {}
  storage_use_azuread = true
}
