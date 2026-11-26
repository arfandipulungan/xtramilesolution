# Parameters only: the logic lives in stacks/aws-3tier and the modules it composes.
module "stack" {
  source = "../../../../stacks/aws-3tier"

  app               = "legacy-web"
  environment       = "dev"
  owner             = "team-web"
  vpc_cidr          = "10.110.0.0/16"
  az_count          = 2
  ami_id            = "ami-0123456789abcdef0" # golden AMI from the image pipeline
  instance_type     = "t3.small"
  min_size          = 1
  max_size          = 2
  db_instance_class = "db.t4g.small"

  # Shared platform resources (security / log-archive accounts)
  certificate_arn    = "arn:aws:acm:ap-southeast-2:111111111111:certificate/00000000-0000-0000-0000-000000000000"
  waf_web_acl_arn    = "arn:aws:wafv2:ap-southeast-2:111111111111:regional/webacl/platform-waf/00000000-0000-0000-0000-000000000000"
  log_archive_bucket = "xtramile-log-archive-apse2"
}

output "codedeploy_group" {
  value = module.stack.codedeploy_group
}
