# Parameters only: the logic lives in stacks/azure-func.
module "stack" {
  source = "../../../../stacks/azure-func"

  app            = "order-events"
  environment    = "dev"
  owner          = "team-orders"
  vnet_cidr      = "10.10.1.0/24"
  sku_name       = "EP1"
  zone_redundant = false
}

output "function_app_name" {
  value = module.stack.function_app_name
}
