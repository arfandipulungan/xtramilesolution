# Pipeline roles for one AWS account/environment (Task 1 + Task 2).
module "naming" {
  source      = "../../modules/shared/naming"
  app         = "github-oidc"
  environment = var.environment
  owner       = "platform"
}

module "github_oidc" {
  source               = "../../modules/aws/github-oidc"
  repository           = var.repository
  environment          = var.environment
  region               = var.region
  state_bucket_arn     = var.state_bucket_arn
  artifact_bucket_arns = var.artifact_bucket_arns
  kms_key_arns         = var.kms_key_arns
  create_oidc_provider = var.create_oidc_provider
  tags                 = module.naming.tags
}
