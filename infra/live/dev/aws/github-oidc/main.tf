# Pipeline roles for dev (bootstrap: applied once by a platform admin, then by the pipeline).
module "stack" {
  source = "../../../../stacks/aws-github-oidc"

  repository           = "arfandipulungan/xtramilesolution"
  environment          = "dev"
  state_bucket_arn     = "arn:aws:s3:::xtramile-tfstate-dev-apse2"
  artifact_bucket_arns = ["arn:aws:s3:::legacy-web-dev-artifacts-222222222222"]
  kms_key_arns         = ["arn:aws:kms:ap-southeast-2:222222222222:alias/legacy-web-dev"]
}

output "role_arns" {
  value = module.stack.role_arns
}
