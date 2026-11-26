output "role_arns" {
  description = "Set as GitHub environment variables (AWS_DEPLOY_ROLE_ARN / AWS_TERRAFORM_ROLE_ARN)"
  value       = { for k, r in aws_iam_role.this : k => r.arn }
}
