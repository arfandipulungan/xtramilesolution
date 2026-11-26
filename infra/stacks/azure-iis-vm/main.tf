# Composition for the legacy .NET Framework 4.8 web app on IIS (Windows VM).
# Inbound web traffic arrives only from the WAF (Application Gateway / Front Door)
# subnet in the hub; admin access only from Azure Bastion.
module "naming" {
  source         = "../../modules/shared/naming"
  app            = var.app
  environment    = var.environment
  owner          = var.owner
  name_overrides = var.name_overrides
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
    snet-vm = {
      cidr = cidrsubnet(var.vnet_cidr, 2, 0)
      nsg_rules = [
        {
          name        = "allow-https-from-waf"
          priority    = 100
          direction   = "Inbound"
          access      = "Allow"
          protocol    = "Tcp"
          port        = "443"
          source      = var.waf_subnet_cidr
          destination = "*"
        },
        {
          name        = "allow-rdp-from-bastion"
          priority    = 110
          direction   = "Inbound"
          access      = "Allow"
          protocol    = "Tcp"
          port        = "3389"
          source      = var.bastion_subnet_cidr
          destination = "*"
        },
        {
          name        = "allow-winrm-from-ansible"
          priority    = 120
          direction   = "Inbound"
          access      = "Allow"
          protocol    = "Tcp"
          port        = "5986"
          source      = var.ansible_runner_cidr
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

# Release packages for the Task 1 IIS deploy (container "releases").
module "release_storage" {
  source                     = "../../modules/azure/storage-account"
  name                       = local.n.storage
  location                   = var.location
  resource_group_name        = azurerm_resource_group.this.name
  replication_type           = var.environment == "prod" ? "ZRS" : "LRS"
  containers                 = ["releases"]
  private_endpoint_subnet_id = module.network.subnet_ids["snet-private-endpoints"]
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  tags                       = module.naming.tags
}

module "vm" {
  source               = "../../modules/azure/windows-vm"
  name                 = local.n.vm
  location             = var.location
  resource_group_name  = azurerm_resource_group.this.name
  subnet_id            = module.network.subnet_ids["snet-vm"]
  size                 = var.vm_size
  key_vault_id         = module.key_vault.id
  release_container_id = module.release_storage.container_ids["releases"]
  tags                 = module.naming.tags
}
