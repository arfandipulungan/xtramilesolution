# Composition for the AWS 3-tier app (e.g. legacy-web): VPC, ALB + WAF,
# EC2 Auto Scaling Group, RDS, locked-down S3, CodeDeploy blue/green.
module "naming" {
  source      = "../../modules/shared/naming"
  app         = var.app
  environment = var.environment
  owner       = var.owner
}

locals {
  n = module.naming.names
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "kms" {
  #checkov:skip=CKV_AWS_111:Standard KMS key policy; access is delegated to IAM policies, resource "*" means this key only
  #checkov:skip=CKV_AWS_356:Standard KMS key policy; resource "*" in a key policy refers to the key itself
  #checkov:skip=CKV_AWS_109:Standard KMS key policy; key administration is governed by IAM and SCPs
  statement {
    sid       = "AccountAdmin"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
  statement {
    sid       = "CloudWatchLogs"
    actions   = ["kms:Encrypt*", "kms:Decrypt*", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:Describe*"]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }
  }
}

# One customer-managed key per app/env: S3, EBS, RDS, Secrets Manager, logs.
resource "aws_kms_key" "this" {
  description             = "${module.naming.base} data key"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.kms.json
  tags                    = module.naming.tags
}

resource "aws_kms_alias" "this" {
  name          = "alias/${module.naming.base}"
  target_key_id = aws_kms_key.this.key_id
}

module "vpc" {
  source             = "../../modules/aws/vpc"
  name               = local.n.vpc
  region             = var.region
  cidr               = var.vpc_cidr
  az_count           = var.az_count
  availability_zones = ["${var.region}a", "${var.region}b", "${var.region}c"]
  single_nat_gateway = var.environment != "prod"
  logs_kms_key_arn   = aws_kms_key.this.arn
  tags               = module.naming.tags
}

module "artifact_bucket" {
  source                  = "../../modules/aws/s3-secure"
  name                    = "${module.naming.base}-artifacts-${data.aws_caller_identity.current.account_id}"
  kms_key_arn             = aws_kms_key.this.arn
  access_log_bucket       = var.log_archive_bucket
  allowed_vpc_endpoint_id = null
  tags                    = module.naming.tags
}

# Customer files / exports: previously over-exposed, now private and VPC-endpoint only.
module "customer_files_bucket" {
  source                  = "../../modules/aws/s3-secure"
  name                    = "${module.naming.base}-customer-files-${data.aws_caller_identity.current.account_id}"
  kms_key_arn             = aws_kms_key.this.arn
  access_log_bucket       = var.log_archive_bucket
  allowed_vpc_endpoint_id = module.vpc.s3_endpoint_id
  admin_role_arns         = var.break_glass_role_arns
  tags                    = module.naming.tags
}

module "alb" {
  source                = "../../modules/aws/alb"
  name                  = local.n.alb
  vpc_id                = module.vpc.vpc_id
  vpc_cidr              = module.vpc.vpc_cidr
  public_subnet_ids     = module.vpc.public_subnet_ids
  certificate_arn       = var.certificate_arn
  waf_web_acl_arn       = var.waf_web_acl_arn
  access_log_bucket     = var.log_archive_bucket
  allowed_ingress_cidrs = var.allowed_ingress_cidrs
  deletion_protection   = true
  tags                  = module.naming.tags
}

module "app" {
  source                   = "../../modules/aws/ec2-asg"
  name                     = local.n.asg
  app                      = var.app
  vpc_id                   = module.vpc.vpc_id
  app_subnet_ids           = module.vpc.app_subnet_ids
  alb_security_group_id    = module.alb.security_group_id
  initial_target_group_arn = module.alb.target_group_arns["blue"]
  artifact_bucket_arn      = module.artifact_bucket.arn
  kms_key_arn              = aws_kms_key.this.arn
  ami_id                   = var.ami_id
  instance_type            = var.instance_type
  min_size                 = var.min_size
  max_size                 = var.max_size
  desired_capacity         = var.min_size
  secret_arns              = [module.db.master_user_secret_arn]
  tags                     = module.naming.tags
}

module "db" {
  source                = "../../modules/aws/rds"
  name                  = local.n.rds
  vpc_id                = module.vpc.vpc_id
  data_subnet_ids       = module.vpc.data_subnet_ids
  app_security_group_id = module.app.security_group_id
  kms_key_arn           = aws_kms_key.this.arn
  db_name               = replace(var.app, "-", "_")
  instance_class        = var.db_instance_class
  multi_az              = var.environment == "prod"
  deletion_protection   = var.environment == "prod"
  tags                  = module.naming.tags
}

module "codedeploy" {
  source                = "../../modules/aws/codedeploy"
  app_name              = local.n.codedeploy_app
  deployment_group_name = local.n.codedeploy_group
  asg_name              = module.app.asg_name
  listener_arn          = module.alb.https_listener_arn
  alb_arn_suffix        = module.alb.arn_suffix
  target_group_names    = module.alb.target_group_names
  tags                  = module.naming.tags
}
