# .NET 8 isolated background/event-driven app on Azure Functions (Elastic Premium:
# VNet integration, private endpoint, deployment slots). Storage via managed identity.
resource "azurerm_service_plan" "this" {
  name                         = var.service_plan_name
  location                     = var.location
  resource_group_name          = var.resource_group_name
  os_type                      = "Linux"
  sku_name                     = var.sku_name
  maximum_elastic_worker_count = var.max_elastic_workers
  zone_balancing_enabled       = var.zone_redundant
  worker_count                 = var.zone_redundant ? 3 : 1
  tags                         = var.tags
}

locals {
  app_settings = merge({
    APPLICATIONINSIGHTS_CONNECTION_STRING = var.app_insights_connection_string
    FUNCTIONS_WORKER_RUNTIME              = "dotnet-isolated"
    WEBSITE_RUN_FROM_PACKAGE              = "1"
    # Identity-based connection for triggers/bindings using the same storage account
    AzureWebJobsStorage__accountName = var.storage_account_name
  }, var.app_settings)

  site_config = {
    minimum_tls_version     = "1.3"
    scm_minimum_tls_version = "1.2"
    ftps_state              = "Disabled"
    vnet_route_all_enabled  = true
    http2_enabled           = true
  }
}

resource "azurerm_linux_function_app" "this" {
  #checkov:skip=CKV_AZURE_17:Event-driven app with no public HTTP surface; reached only via private endpoint
  #checkov:skip=CKV_AZURE_56:No interactive/HTTP users; triggers are queue/event based behind a private endpoint
  name                                           = var.name
  location                                       = var.location
  resource_group_name                            = var.resource_group_name
  service_plan_id                                = azurerm_service_plan.this.id
  storage_account_name                           = var.storage_account_name
  storage_uses_managed_identity                  = true
  https_only                                     = true
  public_network_access_enabled                  = false
  virtual_network_subnet_id                      = var.integration_subnet_id
  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false
  functions_extension_version                    = "~4"
  app_settings                                   = local.app_settings
  tags                                           = var.tags

  identity {
    type = "SystemAssigned"
  }

  site_config {
    minimum_tls_version     = local.site_config.minimum_tls_version
    scm_minimum_tls_version = local.site_config.scm_minimum_tls_version
    ftps_state              = local.site_config.ftps_state
    vnet_route_all_enabled  = local.site_config.vnet_route_all_enabled
    http2_enabled           = local.site_config.http2_enabled

    application_stack {
      dotnet_version              = "8.0"
      use_dotnet_isolated_runtime = true
    }
  }

  lifecycle {
    ignore_changes = [app_settings["WEBSITE_RUN_FROM_PACKAGE"]]
  }
}

resource "azurerm_linux_function_app_slot" "staging" {
  name                                           = "staging"
  function_app_id                                = azurerm_linux_function_app.this.id
  storage_account_name                           = var.storage_account_name
  storage_uses_managed_identity                  = true
  https_only                                     = true
  public_network_access_enabled                  = false
  virtual_network_subnet_id                      = var.integration_subnet_id
  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false
  functions_extension_version                    = "~4"
  app_settings                                   = local.app_settings
  tags                                           = var.tags

  identity {
    type = "SystemAssigned"
  }

  site_config {
    minimum_tls_version     = local.site_config.minimum_tls_version
    scm_minimum_tls_version = local.site_config.scm_minimum_tls_version
    ftps_state              = local.site_config.ftps_state
    vnet_route_all_enabled  = local.site_config.vnet_route_all_enabled
    http2_enabled           = local.site_config.http2_enabled

    application_stack {
      dotnet_version              = "8.0"
      use_dotnet_isolated_runtime = true
    }
  }
}

resource "azurerm_private_endpoint" "this" {
  name                = "pe-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.name}"
    private_connection_resource_id = azurerm_linux_function_app.this.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }
}

locals {
  principals = {
    production = azurerm_linux_function_app.this.identity[0].principal_id
    staging    = azurerm_linux_function_app_slot.staging.identity[0].principal_id
  }
  storage_roles = ["Storage Blob Data Owner", "Storage Queue Data Contributor", "Storage Table Data Contributor"]
  storage_grants = {
    for pair in setproduct(keys(local.principals), local.storage_roles) :
    "${pair[0]}-${pair[1]}" => { principal = local.principals[pair[0]], role = pair[1] }
  }
}

resource "azurerm_role_assignment" "storage" {
  for_each             = local.storage_grants
  scope                = var.storage_account_id
  role_definition_name = each.value.role
  principal_id         = each.value.principal
}

resource "azurerm_role_assignment" "kv_secrets_user" {
  for_each             = local.principals
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  name                       = "diag-${var.name}"
  target_resource_id         = azurerm_linux_function_app.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "FunctionAppLogs"
  }
  enabled_metric {
    category = "AllMetrics"
  }
}
