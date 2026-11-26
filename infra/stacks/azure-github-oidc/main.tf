# Pipeline identities for one Azure subscription/environment (Task 1 + Task 2).
module "naming" {
  source      = "../../modules/shared/naming"
  app         = "github-oidc"
  environment = var.environment
  owner       = "platform"
}

resource "azurerm_resource_group" "this" {
  name     = module.naming.names.resource_group
  location = var.location
  tags     = module.naming.tags
}

module "github_oidc" {
  source                = "../../modules/azure/github-oidc"
  repository            = var.repository
  environment           = var.environment
  location              = var.location
  resource_group_name   = azurerm_resource_group.this.name
  subscription_id_scope = var.subscription_id_scope
  state_container_id    = var.state_container_id
  deploy_scopes         = var.deploy_scopes
  tags                  = module.naming.tags
}
