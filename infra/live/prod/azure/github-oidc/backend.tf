# Remote state: Azure Storage, Entra ID auth (no account keys), blob-lease locking.
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-prod"
    storage_account_name = "sttfstateprodaue"
    container_name       = "tfstate"
    key                  = "prod/azure/github-oidc.tfstate"
    use_azuread_auth     = true
  }
}
