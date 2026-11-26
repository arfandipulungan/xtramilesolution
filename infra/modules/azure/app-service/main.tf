# .NET 8 Web API on App Service: private by default, managed identity,
# staging slot for zero-downtime swap + rollback (used by the Task 1 pipeline).
resource "azurerm_service_plan" "this" {
  name                   = var.service_plan_name
  location               = var.location
  resource_group_name    = var.resource_group_name
  os_type                = "Linux"
  sku_name               = var.sku_name
  worker_count           = var.worker_count
  zone_balancing_enabled = var.zone_redundant
  tags                   = var.tags
}

locals {
  app_settings = merge({
    APPLICATIONINSIGHTS_CONNECTION_STRING = var.app_insights_connection_string
    ASPNETCORE_ENVIRONMENT                = var.aspnetcore_environment
    WEBSITE_RUN_FROM_PACKAGE              = "1"
  }, var.app_settings)
}

resource "azurerm_linux_web_app" "this" {
  #checkov:skip=CKV_AZURE_17:Callers authenticate with Entra ID tokens (auth_settings_v2); mTLS is optional via client_certificate_enabled
  #checkov:skip=CKV_AZURE_88:Stateless API, no file share needed
  name                                           = var.name
  location                                       = var.location
  resource_group_name                            = var.resource_group_name
  service_plan_id                                = azurerm_service_plan.this.id
  https_only                                     = true
  public_network_access_enabled                  = var.public_network_access_enabled
  virtual_network_subnet_id                      = var.integration_subnet_id
  client_certificate_enabled                     = var.client_certificate_enabled
  client_certificate_mode                        = var.client_certificate_enabled ? "Required" : "Optional"
  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false
  app_settings                                   = local.app_settings
  tags                                           = var.tags

  identity {
    type = "SystemAssigned"
  }

  # Replaces the static shared API key: every call must carry an Entra ID token
  # for this API's audience (the AWS tier gets one via workload identity federation).
  auth_settings_v2 {
    auth_enabled           = true
    require_authentication = true
    unauthenticated_action = "Return401"
    default_provider       = "azureactivedirectory"
    excluded_paths         = ["/health"]

    active_directory_v2 {
      client_id            = var.entra_auth.client_id
      tenant_auth_endpoint = "https://login.microsoftonline.com/${var.entra_auth.tenant_id}/v2.0"
      allowed_audiences    = var.entra_auth.allowed_audiences
    }

    login {
      token_store_enabled = false
    }
  }

  site_config {
    always_on                         = true
    http2_enabled                     = true
    minimum_tls_version               = "1.3"
    scm_minimum_tls_version           = "1.2"
    ftps_state                        = "Disabled"
    vnet_route_all_enabled            = true
    health_check_path                 = "/health"
    health_check_eviction_time_in_min = 5

    # Self-healing: recycle the worker on a burst of 5xx (the health check evicts bad instances too).
    auto_heal_setting {
      action {
        action_type                    = "Recycle"
        minimum_process_execution_time = "00:05:00"
      }
      trigger {
        status_code {
          count             = 50
          interval          = "00:05:00"
          status_code_range = "500-599"
        }
      }
    }

    application_stack {
      dotnet_version = "8.0"
    }
  }

  logs {
    detailed_error_messages = true
    failed_request_tracing  = true
    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 35
      }
    }
  }

  lifecycle {
    # The pipeline swaps slots and deploys packages; Terraform owns config, not the running build.
    ignore_changes = [app_settings["WEBSITE_RUN_FROM_PACKAGE"]]
  }
}

resource "azurerm_linux_web_app_slot" "staging" {
  name                                           = "staging"
  app_service_id                                 = azurerm_linux_web_app.this.id
  https_only                                     = true
  public_network_access_enabled                  = false
  virtual_network_subnet_id                      = var.integration_subnet_id
  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false
  app_settings                                   = local.app_settings
  tags                                           = var.tags

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on                         = true
    http2_enabled                     = true
    minimum_tls_version               = "1.3"
    scm_minimum_tls_version           = "1.2"
    ftps_state                        = "Disabled"
    vnet_route_all_enabled            = true
    health_check_path                 = "/health"
    health_check_eviction_time_in_min = 5

    # Self-healing: recycle the worker on a burst of 5xx (the health check evicts bad instances too).
    auto_heal_setting {
      action {
        action_type                    = "Recycle"
        minimum_process_execution_time = "00:05:00"
      }
      trigger {
        status_code {
          count             = 50
          interval          = "00:05:00"
          status_code_range = "500-599"
        }
      }
    }

    application_stack {
      dotnet_version = "8.0"
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
    private_connection_resource_id = azurerm_linux_web_app.this.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }
}

# App reads secrets from Key Vault with its managed identity (Key Vault references).
resource "azurerm_role_assignment" "kv_secrets_user" {
  for_each = {
    production = azurerm_linux_web_app.this.identity[0].principal_id
    staging    = azurerm_linux_web_app_slot.staging.identity[0].principal_id
  }

  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  name                       = "diag-${var.name}"
  target_resource_id         = azurerm_linux_web_app.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AppServiceHTTPLogs"
  }
  enabled_log {
    category = "AppServiceConsoleLogs"
  }
  enabled_log {
    category = "AppServiceAuditLogs"
  }
  enabled_metric {
    category = "AllMetrics"
  }
}
