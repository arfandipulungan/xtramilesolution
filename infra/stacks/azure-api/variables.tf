variable "app" { type = string }
variable "environment" { type = string }
variable "owner" { type = string }

variable "location" {
  type    = string
  default = "australiaeast"
}

variable "vnet_cidr" {
  description = "Spoke VNet CIDR (/24 or larger); must not overlap AWS VPCs"
  type        = string
}

variable "trusted_caller_cidr" {
  description = "Who may call the API privately, e.g. the AWS app-tier subnets over the cross-cloud link"
  type        = string
}

variable "entra_auth" {
  description = "Entra ID app registration protecting the API"
  type = object({
    tenant_id         = string
    client_id         = string
    allowed_audiences = list(string)
  })
}

variable "sku_name" {
  type    = string
  default = "P0v3"
}

variable "worker_count" {
  type    = number
  default = 2
}

variable "zone_redundant" {
  type    = bool
  default = false
}

variable "app_settings" {
  type    = map(string)
  default = {}
}
