variable "app" { type = string }
variable "environment" { type = string }
variable "owner" { type = string }

variable "region" {
  type    = string
  default = "ap-southeast-2"
}

variable "vpc_cidr" {
  description = "Must not overlap Azure VNets"
  type        = string
}

variable "az_count" {
  type    = number
  default = 2
}

variable "ami_id" {
  description = "Hardened golden AMI ID"
  type        = string
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "min_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 4
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.medium"
}

variable "certificate_arn" {
  description = "ACM certificate for the ALB HTTPS listener"
  type        = string
}

variable "waf_web_acl_arn" {
  description = "Shared AWS WAF web ACL from the platform/security account"
  type        = string
}

variable "log_archive_bucket" {
  description = "Central log-archive bucket (ALB + S3 access logs)"
  type        = string
}

variable "allowed_ingress_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "break_glass_role_arns" {
  type    = list(string)
  default = []
}

variable "name_overrides" {
  description = "Real names of imported (brownfield) resources; see modules/shared/naming"
  type        = map(string)
  default     = {}
}
