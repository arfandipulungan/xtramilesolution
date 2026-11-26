# Composition for a .NET 8 API on Azure App Service (e.g. customer-api).
# One call per app per environment from infra/live/<env>/azure/<app>.
module "naming" {
  source      = "../../modules/shared/naming"
  app         = var.app
  environment = var.environment
  owner       = var.owner
}

locals {
  n = module.naming.names
}

resource "azurerm_resource_group" "this" {
  name     = local.n.resource_group
  location = var.location
  tags     = module.naming.tags
}

module "monitoring" {
  source              = "../../modules/azure/monitoring"
  log_analytics_name  = local.n.log_analytics
  app_insights_name   = local.n.app_insights
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = module.naming.tags
}

# Spoke VNet for the app; peered to the platform hub (VPN/ExpressRoute gateway,
# DNS resolver) which is owned by the platform stack, not by each app.
module "network" {
  source              = "../../modules/azure/network"
  name                = local.n.vnet
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [var.vnet_cidr]
  tags                = module.naming.tags

  subnets = {
    snet-app-integration = {
      cidr       = cidrsubnet(var.vnet_cidr, 2, 0)
      delegation = "Microsoft.Web/serverFarms"
    }
    snet-private-endpoints = {
      cidr = cidrsubnet(var.vnet_cidr, 2, 1)
      nsg_rules = [
        {
          name        = "allow-https-from-trusted"
          priority    = 100
          direction   = "Inbound"
          access      = "Allow"
          protocol    = "Tcp"
          port        = "443"
          source      = var.trusted_caller_cidr
          destination = "*"
        },
        {
          name        = "deny-all-inbound"
          priority    = 4096
          direction   = "Inbound"
          access      = "Deny"
          protocol    = "*"
          port        = "*"
          source      = "*"
          destination = "*"
        },
      ]
    }
  }
}

module "key_vault" {
  source                     = "../../modules/azure/key-vault"
  name                       = local.n.key_vault
  location                   = var.location
  resource_group_name        = azurerm_resource_group.this.name
  private_endpoint_subnet_id = module.network.subnet_ids["snet-private-endpoints"]
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  tags                       = module.naming.tags
}

module "app_service" {
  source                         = "../../modules/azure/app-service"
  name                           = local.n.app_service
  service_plan_name              = local.n.service_plan
  location                       = var.location
  resource_group_name            = azurerm_resource_group.this.name
  sku_name                       = var.sku_name
  worker_count                   = var.worker_count
  zone_redundant                 = var.zone_redundant
  integration_subnet_id          = module.network.subnet_ids["snet-app-integration"]
  private_endpoint_subnet_id     = module.network.subnet_ids["snet-private-endpoints"]
  key_vault_id                   = module.key_vault.id
  log_analytics_workspace_id     = module.monitoring.log_analytics_workspace_id
  app_insights_connection_string = module.monitoring.app_insights_connection_string
  aspnetcore_environment         = var.environment == "prod" ? "Production" : "Staging"
  app_settings                   = var.app_settings
  entra_auth                     = var.entra_auth
  tags                           = module.naming.tags
}
