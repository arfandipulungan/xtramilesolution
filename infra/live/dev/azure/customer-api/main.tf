# Parameters only: the logic lives in stacks/azure-api and the modules it composes.
module "stack" {
  source = "../../../../stacks/azure-api"

  app                 = "customer-api"
  environment         = "dev"
  owner               = "team-customer"
  vnet_cidr           = "10.10.0.0/24"
  trusted_caller_cidr = "10.110.0.0/16"
  sku_name            = "P0v3"
  worker_count        = 1
  entra_auth = {
    tenant_id         = "00000000-0000-0000-0000-000000000000"
    client_id         = "11111111-1111-1111-1111-111111111111"
    allowed_audiences = ["api://customer-api-dev"]
  }
  zone_redundant = false
}

output "app_service_name" {
  value = module.stack.app_service_name
}
