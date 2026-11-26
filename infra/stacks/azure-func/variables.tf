variable "app" { type = string }
variable "environment" { type = string }
variable "owner" { type = string }

variable "location" {
  type    = string
  default = "australiaeast"
}

variable "vnet_cidr" {
  description = "Spoke VNet CIDR (/24 or larger); must not overlap other VNets or AWS VPCs"
  type        = string
}

variable "sku_name" {
  type    = string
  default = "EP1"
}

variable "zone_redundant" {
  type    = bool
  default = false
}

variable "app_settings" {
  type    = map(string)
  default = {}
}
