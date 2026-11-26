# Remote state: Azure Storage, Entra ID auth (no account keys), blob-lease locking.
# The state storage account is private, versioned, soft-delete enabled.
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-dev"
    storage_account_name = "sttfstatedevaue"
    container_name       = "tfstate"
    key                  = "dev/azure/customer-api.tfstate"
    use_azuread_auth     = true
  }
}
