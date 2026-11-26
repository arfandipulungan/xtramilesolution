# Brownfield import for infra/live/prod/azure/customer-api (copy into that folder in a
# migration PR, together with the name_overrides in main.tf; delete after the apply).
# IDs are placeholders: take the real ones from Azure Resource Graph or aztfexport.
#
# Existing, click-built resources (as found in the inventory):
#   resource group  rg-prod-custapi
#   plan            asp-custapi-prod
#   web app         custapi-prod-web   (.NET 8 Web API)
#
# Everything else in the stack (VNet, private endpoint, Key Vault, staging slot,
# monitoring) does not exist yet and is created by the same apply.

import {
  to = module.stack.azurerm_resource_group.this
  id = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/rg-prod-custapi"
}

import {
  to = module.stack.module.app_service.azurerm_service_plan.this
  id = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/rg-prod-custapi/providers/Microsoft.Web/serverFarms/asp-custapi-prod"
}

import {
  to = module.stack.module.app_service.azurerm_linux_web_app.this
  id = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/rg-prod-custapi/providers/Microsoft.Web/sites/custapi-prod-web"
}
