# Remote state: Azure Storage, Entra ID auth (no account keys), blob-lease locking.
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-dev"
    storage_account_name = "sttfstatedevaue"
    container_name       = "tfstate"
    key                  = "dev/azure/github-oidc.tfstate"
    use_azuread_auth     = true
  }
}
