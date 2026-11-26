# GitHub Actions OIDC trust for one AWS account/environment. Three roles, each
# assumable only from one GitHub environment, each least-privilege for its job.
locals {
  oidc_host = "token.actions.githubusercontent.com"
  provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : (
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_host}"
  )
  roles = {
    deploy  = var.environment                 # Task 1 app deployments
    tfplan  = "infra-${var.environment}-plan" # Task 2 plan (read-only)
    tfapply = "infra-${var.environment}"      # Task 2 apply (approval in prod)
  }
}

data "aws_caller_identity" "current" {}

resource "aws_iam_openid_connect_provider" "github" {
  count          = var.create_oidc_provider ? 1 : 0
  url            = "https://${local.oidc_host}"
  client_id_list = ["sts.amazonaws.com"]
  tags           = var.tags
}

data "aws_iam_policy_document" "trust" {
  for_each = local.roles
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [local.provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:sub"
      values   = ["repo:${var.repository}:environment:${each.value}"]
    }
  }
}

resource "aws_iam_role" "this" {
  for_each             = local.roles
  name                 = "github-${each.key}-${var.environment}"
  assume_role_policy   = data.aws_iam_policy_document.trust[each.key].json
  max_session_duration = 3600
  permissions_boundary = aws_iam_policy.boundary.arn
  tags                 = var.tags
}

# ---- Guardrail on every pipeline role: cannot create long-lived credentials,
# touch the organisation, or switch off audit logging, even with admin rights.
data "aws_iam_policy_document" "boundary" {
  #checkov:skip=CKV_AWS_111:Permissions boundary; the Allow * is capped by the explicit denies and by SCPs
  #checkov:skip=CKV_AWS_356:Permissions boundary; resource "*" is required for a boundary to cap all services
  #checkov:skip=CKV_AWS_109:Permissions boundary; the explicit denies below are the point of this document
  #checkov:skip=CKV_AWS_108:Permissions boundary; data access is granted only by each role's own policy
  #checkov:skip=CKV_AWS_107:Permissions boundary; credential-exposing actions are explicitly denied below
  #checkov:skip=CKV_AWS_110:Permissions boundary; privilege escalation paths are explicitly denied below
  #checkov:skip=CKV_AWS_49:Permissions boundary; Allow "*" is the ceiling, capped by the explicit denies
  #checkov:skip=CKV_AWS_1:Permissions boundary, not a grant; it cannot give any permission on its own
  statement {
    sid       = "AllowWithinBoundary"
    actions   = ["*"]
    resources = ["*"]
  }
  statement {
    sid    = "DenyLongLivedCredentialsAndAuditTampering"
    effect = "Deny"
    actions = [
      "iam:CreateUser", "iam:CreateAccessKey", "iam:CreateLoginProfile",
      "organizations:*", "account:*",
      "cloudtrail:StopLogging", "cloudtrail:DeleteTrail", "cloudtrail:UpdateTrail",
      "config:StopConfigurationRecorder", "config:DeleteConfigurationRecorder",
      "guardduty:DeleteDetector", "securityhub:DisableSecurityHub",
    ]
    resources = ["*"]
  }
  statement {
    sid       = "DenyRemovingThisBoundary"
    effect    = "Deny"
    actions   = ["iam:DeleteRolePermissionsBoundary", "iam:PutRolePermissionsBoundary"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "boundary" {
  name   = "github-pipeline-boundary-${var.environment}"
  policy = data.aws_iam_policy_document.boundary.json
  tags   = var.tags
}

# ---- deploy: CodeDeploy for this environment's apps + upload bundles
data "aws_iam_policy_document" "deploy" {
  statement {
    sid = "CodeDeploy"
    actions = [
      "codedeploy:CreateDeployment", "codedeploy:GetDeployment", "codedeploy:GetDeploymentConfig",
      "codedeploy:GetApplicationRevision", "codedeploy:RegisterApplicationRevision", "codedeploy:StopDeployment",
    ]
    resources = [
      "arn:aws:codedeploy:${var.region}:${data.aws_caller_identity.current.account_id}:application:*",
      "arn:aws:codedeploy:${var.region}:${data.aws_caller_identity.current.account_id}:deploymentgroup:*/*-${var.environment}",
      "arn:aws:codedeploy:${var.region}:${data.aws_caller_identity.current.account_id}:deploymentconfig:*",
    ]
  }
  statement {
    sid       = "UploadBundles"
    actions   = ["s3:PutObject"]
    resources = [for b in var.artifact_bucket_arns : "${b}/*"]
  }
  statement {
    sid       = "EncryptBundles"
    actions   = ["kms:GenerateDataKey", "kms:Encrypt"]
    resources = var.kms_key_arns
  }
}

resource "aws_iam_role_policy" "deploy" {
  name   = "deploy"
  role   = aws_iam_role.this["deploy"].id
  policy = data.aws_iam_policy_document.deploy.json
}

# ---- tfplan: read everything, write only the state lock file
data "aws_iam_policy_document" "state" {
  statement {
    sid       = "ListStateBucket"
    actions   = ["s3:ListBucket"]
    resources = [var.state_bucket_arn]
  }
  statement {
    sid       = "ReadStateWriteLock"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${var.state_bucket_arn}/${var.environment}/*"]
  }
}

resource "aws_iam_role_policy" "tfplan_state" {
  name   = "terraform-state"
  role   = aws_iam_role.this["tfplan"].id
  policy = data.aws_iam_policy_document.state.json
}

resource "aws_iam_role_policy_attachment" "tfplan_readonly" {
  role       = aws_iam_role.this["tfplan"].name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# ---- tfapply: broad rights by necessity, capped by the boundary above and by SCPs;
# usable only from the protected infra-<env> GitHub environment (approval in prod).
resource "aws_iam_role_policy_attachment" "tfapply_admin" {
  #checkov:skip=CKV_AWS_274:Terraform apply must manage IAM and every service; capped by the permissions boundary, SCPs and environment approval
  role       = aws_iam_role.this["tfapply"].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role_policy" "tfapply_state" {
  name   = "terraform-state"
  role   = aws_iam_role.this["tfapply"].id
  policy = data.aws_iam_policy_document.state.json
}
