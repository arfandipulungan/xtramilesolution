# Private storage account: Entra ID auth only (no shared keys), no public access,
# TLS 1.2+, blob soft delete + versioning, private endpoints per sub-resource.
resource "azurerm_storage_account" "this" {
  #checkov:skip=CKV2_AZURE_1:Microsoft-managed keys with infrastructure encryption; CMK is a roadmap item for regulated data
  #checkov:skip=CKV_AZURE_59:public_network_access = "Disabled" (azurerm v5 attribute); access only via private endpoints
  #checkov:skip=CKV_AZURE_206:ZRS in prod / LRS in dev by design; geo-redundancy is a DR roadmap item
  #checkov:skip=CKV_AZURE_43:Name comes from the shared naming module, which enforces the format
  #checkov:skip=CKV_AZURE_33:Queue/table/blob logging goes to Log Analytics via diagnostic settings (below)
  #checkov:skip=CKV2_AZURE_21:Blob read/write/delete logging goes to Log Analytics via diagnostic settings (below)
  name                              = var.name
  location                          = var.location
  resource_group_name               = var.resource_group_name
  account_tier                      = "Standard"
  account_replication_type          = var.replication_type
  account_kind                      = "StorageV2"
  min_tls_version                   = "TLS1_2"
  https_traffic_only_enabled        = true
  shared_access_key_enabled         = false
  default_to_oauth_authentication   = true
  allow_nested_items_to_be_public   = false
  public_network_access             = "Disabled"
  cross_tenant_replication_enabled  = false
  infrastructure_encryption_enabled = true
  local_user_enabled                = false
  tags                              = var.tags

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 30
    }
    container_delete_retention_policy {
      days = 30
    }
  }

  sas_policy {
    expiration_period = "01.00:00:00"
  }

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices", "Logging", "Metrics"]
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "this" {
  #checkov:skip=CKV2_AZURE_21:Blob read/write/delete logging goes to Log Analytics via the diagnostic settings below
  for_each              = toset(var.containers)
  name                  = each.value
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

resource "azurerm_private_endpoint" "this" {
  for_each            = toset(var.private_endpoint_subresources)
  name                = "pe-${var.name}-${each.value}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.name}-${each.value}"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = [each.value]
    is_manual_connection           = false
  }
}

# Read/write/delete logs for every enabled service (blob always, queue/table when used).
resource "azurerm_monitor_diagnostic_setting" "service" {
  for_each                   = toset(distinct(concat(["blob"], [for s in var.private_endpoint_subresources : s if contains(["queue", "table"], s)])))
  name                       = "diag-${var.name}-${each.value}"
  target_resource_id         = "${azurerm_storage_account.this.id}/${each.value}Services/default"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "StorageRead"
  }
  enabled_log {
    category = "StorageWrite"
  }
  enabled_log {
    category = "StorageDelete"
  }
}
