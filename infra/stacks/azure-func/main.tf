# Composition for a .NET 8 background/event-driven app on Azure Functions.
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

module "network" {
  source              = "../../modules/azure/network"
  name                = local.n.vnet
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [var.vnet_cidr]
  tags                = module.naming.tags

  subnets = {
    snet-func-integration = {
      cidr       = cidrsubnet(var.vnet_cidr, 2, 0)
      delegation = "Microsoft.Web/serverFarms"
    }
    snet-private-endpoints = {
      cidr = cidrsubnet(var.vnet_cidr, 2, 1)
      nsg_rules = [
        {
          name        = "allow-https-from-vnet"
          priority    = 100
          direction   = "Inbound"
          access      = "Allow"
          protocol    = "Tcp"
          port        = "443"
          source      = "VirtualNetwork"
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

# Functions runtime storage (triggers, leases, queues): private, identity-based access.
module "storage" {
  source                        = "../../modules/azure/storage-account"
  name                          = local.n.storage
  location                      = var.location
  resource_group_name           = azurerm_resource_group.this.name
  replication_type              = var.environment == "prod" ? "ZRS" : "LRS"
  private_endpoint_subnet_id    = module.network.subnet_ids["snet-private-endpoints"]
  private_endpoint_subresources = ["blob", "queue", "table"]
  log_analytics_workspace_id    = module.monitoring.log_analytics_workspace_id
  tags                          = module.naming.tags
}

module "function_app" {
  source                         = "../../modules/azure/function-app"
  name                           = local.n.function_app
  service_plan_name              = local.n.service_plan
  location                       = var.location
  resource_group_name            = azurerm_resource_group.this.name
  sku_name                       = var.sku_name
  zone_redundant                 = var.zone_redundant
  storage_account_name           = module.storage.name
  storage_account_id             = module.storage.id
  integration_subnet_id          = module.network.subnet_ids["snet-func-integration"]
  private_endpoint_subnet_id     = module.network.subnet_ids["snet-private-endpoints"]
  key_vault_id                   = module.key_vault.id
  log_analytics_workspace_id     = module.monitoring.log_analytics_workspace_id
  app_insights_connection_string = module.monitoring.app_insights_connection_string
  app_settings                   = var.app_settings
  tags                           = module.naming.tags
}
