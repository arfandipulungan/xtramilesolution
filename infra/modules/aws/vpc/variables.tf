variable "name" { type = string }
variable "region" { type = string }
variable "tags" { type = map(string) }

variable "cidr" {
  description = "VPC CIDR; must not overlap the Azure VNets (cross-cloud private link)"
  type        = string
}

variable "availability_zones" {
  description = "Ordered AZ names to place subnets in"
  type        = list(string)
}

variable "az_count" {
  type    = number
  default = 2
  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "Use 2 or 3 availability zones."
  }
}

variable "single_nat_gateway" {
  description = "true for dev (cost), false for prod (one NAT per AZ)"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  type    = number
  default = 365
}

variable "logs_kms_key_arn" {
  description = "KMS key for CloudWatch log encryption"
  type        = string
}
