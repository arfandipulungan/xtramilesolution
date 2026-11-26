variable "name" { type = string }
variable "service_plan_name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tags" { type = map(string) }

variable "sku_name" {
  description = "Plan SKU; deployment slots need Standard (S1) or higher, P0v3+ recommended"
  type        = string
  default     = "P0v3"
}

variable "worker_count" {
  type    = number
  default = 2
}

variable "zone_redundant" {
  description = "Spread instances across availability zones (prod)"
  type        = bool
  default     = false
}

variable "integration_subnet_id" {
  description = "Subnet delegated to Microsoft.Web/serverFarms for outbound VNet integration"
  type        = string
}

variable "private_endpoint_subnet_id" {
  description = "Subnet for the inbound private endpoint"
  type        = string
}

variable "public_network_access_enabled" {
  description = "Keep false: the API is reached only over the private endpoint / cross-cloud link"
  type        = bool
  default     = false
}

variable "client_certificate_enabled" {
  description = "Require mTLS client certificates (optional defence in depth for the cross-cloud call)"
  type        = bool
  default     = false
}

variable "entra_auth" {
  description = "Entra ID app registration that protects the API (App Service Authentication)"
  type = object({
    tenant_id         = string
    client_id         = string
    allowed_audiences = list(string)
  })
}

variable "key_vault_id" { type = string }
variable "log_analytics_workspace_id" { type = string }

variable "app_insights_connection_string" {
  type      = string
  sensitive = true
}

variable "aspnetcore_environment" {
  type    = string
  default = "Production"
}

variable "app_settings" {
  description = "Extra settings; reference secrets as @Microsoft.KeyVault(SecretUri=...), never plain values"
  type        = map(string)
  default     = {}
}
