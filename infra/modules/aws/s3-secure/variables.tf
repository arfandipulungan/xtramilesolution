variable "name" { type = string }
variable "kms_key_arn" { type = string }
variable "tags" { type = map(string) }

variable "noncurrent_version_days" {
  type    = number
  default = 90
}

variable "access_log_bucket" {
  description = "Bucket that receives server access logs (null = disabled)"
  type        = string
  default     = null
}

variable "allowed_vpc_endpoint_id" {
  description = "If set, object access is denied unless it comes through this VPC endpoint"
  type        = string
  default     = null
}

variable "admin_role_arns" {
  description = "Roles exempt from the VPC endpoint restriction (pipeline, break-glass)"
  type        = list(string)
  default     = []
}
