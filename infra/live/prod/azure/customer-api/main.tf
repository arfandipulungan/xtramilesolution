# Parameters only: the logic lives in stacks/azure-api and the modules it composes.
module "stack" {
  source = "../../../../stacks/azure-api"

  app                 = "customer-api"
  environment         = "prod"
  owner               = "team-customer"
  vnet_cidr           = "10.20.0.0/24"
  trusted_caller_cidr = "10.120.0.0/16"
  sku_name            = "P1v3"
  worker_count        = 3
  entra_auth = {
    tenant_id         = "00000000-0000-0000-0000-000000000000"
    client_id         = "11111111-1111-1111-1111-111111111111"
    allowed_audiences = ["api://customer-api-prod"]
  }
  zone_redundant = true
}

output "app_service_name" {
  value = module.stack.app_service_name
}
