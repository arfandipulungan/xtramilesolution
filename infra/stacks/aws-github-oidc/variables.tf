variable "repository" { type = string }
variable "environment" { type = string }
variable "state_bucket_arn" { type = string }
variable "artifact_bucket_arns" { type = list(string) }
variable "kms_key_arns" { type = list(string) }

variable "region" {
  type    = string
  default = "ap-southeast-2"
}

variable "create_oidc_provider" {
  type    = bool
  default = true
}
