variable "name" { type = string }
variable "service_plan_name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "storage_account_name" { type = string }
variable "storage_account_id" { type = string }
variable "integration_subnet_id" { type = string }
variable "private_endpoint_subnet_id" { type = string }
variable "key_vault_id" { type = string }
variable "log_analytics_workspace_id" { type = string }
variable "tags" { type = map(string) }

variable "app_insights_connection_string" {
  type      = string
  sensitive = true
}

variable "sku_name" {
  description = "Elastic Premium (EP1+) for VNet integration and deployment slots"
  type        = string
  default     = "EP1"
}

variable "max_elastic_workers" {
  type    = number
  default = 10
}

variable "zone_redundant" {
  type    = bool
  default = false
}

variable "app_settings" {
  description = "Extra settings; secrets as Key Vault references only"
  type        = map(string)
  default     = {}
}
