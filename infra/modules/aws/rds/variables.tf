variable "name" { type = string }
variable "vpc_id" { type = string }
variable "data_subnet_ids" { type = list(string) }
variable "app_security_group_id" { type = string }
variable "kms_key_arn" { type = string }
variable "tags" { type = map(string) }

variable "engine" {
  type    = string
  default = "postgres"
}

variable "engine_version" {
  type    = string
  default = "16"
}

variable "parameter_group_family" {
  type    = string
  default = "postgres16"
}

variable "port" {
  type    = number
  default = 5432
}

variable "cloudwatch_log_exports" {
  type    = list(string)
  default = ["postgresql", "upgrade"]
}

variable "instance_class" {
  type    = string
  default = "db.t4g.medium"
}

variable "allocated_storage_gb" {
  type    = number
  default = 50
}

variable "db_name" { type = string }

variable "master_username" {
  type    = string
  default = "dbadmin"
}

variable "multi_az" {
  type    = bool
  default = true
}

variable "backup_retention_days" {
  description = "Essential 8: regular backups"
  type        = number
  default     = 14
}

variable "deletion_protection" {
  type    = bool
  default = true
}
