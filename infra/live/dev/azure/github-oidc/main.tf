# Pipeline identities for dev (bootstrap: applied once by a platform admin, then by the pipeline).
module "stack" {
  source = "../../../../stacks/azure-github-oidc"

  repository            = "arfandipulungan/xtramilesolution"
  environment           = "dev"
  subscription_id_scope = "/subscriptions/00000000-0000-0000-0000-000000000001"
  state_container_id    = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/rg-tfstate-dev/providers/Microsoft.Storage/storageAccounts/sttfstatedevaue/blobServices/default/containers/tfstate"
  deploy_scopes = [
    "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/rg-customer-api-dev",
    "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/rg-order-events-dev",
    "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/rg-legacy-portal-dev",
  ]
}

output "client_ids" {
  value = module.stack.client_ids
}
