# Pipeline roles for prod (bootstrap: applied once by a platform admin, then by the pipeline).
module "stack" {
  source = "../../../../stacks/aws-github-oidc"

  repository           = "arfandipulungan/xtramilesolution"
  environment          = "prod"
  state_bucket_arn     = "arn:aws:s3:::xtramile-tfstate-prod-apse2"
  artifact_bucket_arns = ["arn:aws:s3:::legacy-web-prod-artifacts-333333333333"]
  kms_key_arns         = ["arn:aws:kms:ap-southeast-2:333333333333:alias/legacy-web-prod"]
}

output "role_arns" {
  value = module.stack.role_arns
}
