variable "log_analytics_name" { type = string }
variable "app_insights_name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tags" { type = map(string) }

variable "retention_days" {
  description = "Log retention; audit evidence needs at least 90 days hot"
  type        = number
  default     = 90
}
