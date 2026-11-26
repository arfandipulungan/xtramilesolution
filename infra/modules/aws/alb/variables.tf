variable "name" { type = string }
variable "vpc_id" { type = string }
variable "vpc_cidr" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "certificate_arn" { type = string }
variable "access_log_bucket" { type = string }
variable "tags" { type = map(string) }

variable "waf_web_acl_arn" {
  description = "AWS WAF web ACL (managed rule groups) attached to the ALB"
  type        = string
}

variable "target_port" {
  type    = number
  default = 5000
}

variable "allowed_ingress_cidrs" {
  description = "Who may reach the ALB; narrow to the CDN/edge ranges when one is in front"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_http_redirect" {
  description = "Open port 80 only to redirect to HTTPS; off by default (edge/CDN handles redirects)"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  type    = bool
  default = true
}
