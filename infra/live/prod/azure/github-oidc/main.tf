# Pipeline identities for prod (bootstrap: applied once by a platform admin, then by the pipeline).
module "stack" {
  source = "../../../../stacks/azure-github-oidc"

  repository            = "arfandipulungan/xtramilesolution"
  environment           = "prod"
  subscription_id_scope = "/subscriptions/00000000-0000-0000-0000-000000000002"
  state_container_id    = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/rg-tfstate-prod/providers/Microsoft.Storage/storageAccounts/sttfstateprodaue/blobServices/default/containers/tfstate"
  deploy_scopes = [
    "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/rg-customer-api-prod",
    "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/rg-order-events-prod",
    "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/rg-legacy-portal-prod",
  ]
}

output "client_ids" {
  value = module.stack.client_ids
}
