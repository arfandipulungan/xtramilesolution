variable "repository" {
  description = "owner/repo allowed to assume these roles"
  type        = string
}
variable "environment" { type = string }
variable "region" { type = string }
variable "state_bucket_arn" { type = string }
variable "tags" { type = map(string) }

variable "create_oidc_provider" {
  description = "Only one GitHub OIDC provider may exist per account"
  type        = bool
  default     = true
}

variable "artifact_bucket_arns" {
  type = list(string)
}

variable "kms_key_arns" {
  type = list(string)
}
