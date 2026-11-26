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

variable "waf_subnet_cidr" {
  description = "Hub subnet of the WAF (Application Gateway / Front Door origin) allowed to reach IIS"
  type        = string
}

variable "bastion_subnet_cidr" {
  description = "AzureBastionSubnet in the hub (admin access, no public RDP)"
  type        = string
}

variable "ansible_runner_cidr" {
  description = "Self-hosted runner subnet allowed to reach WinRM over HTTPS"
  type        = string
}

variable "vm_size" {
  type    = string
  default = "Standard_D2s_v5"
}
