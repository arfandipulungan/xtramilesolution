# Parameters only: the logic lives in stacks/azure-func.
module "stack" {
  source = "../../../../stacks/azure-func"

  app            = "order-events"
  environment    = "prod"
  owner          = "team-orders"
  vnet_cidr      = "10.20.1.0/24"
  sku_name       = "EP2"
  zone_redundant = true
}

output "function_app_name" {
  value = module.stack.function_app_name
}
