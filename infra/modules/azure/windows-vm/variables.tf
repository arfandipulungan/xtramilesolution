variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "subnet_id" { type = string }
variable "key_vault_id" { type = string }
variable "release_container_id" { type = string }
variable "tags" { type = map(string) }

variable "size" {
  type    = string
  default = "Standard_D2s_v5"
}

variable "zone" {
  type    = string
  default = "1"
}

variable "image_sku" {
  description = "Windows Server image; replaced by a hardened golden image (Packer) in the image pipeline"
  type        = string
  default     = "2022-datacenter-azure-edition"
}

variable "ansible_group" {
  type    = string
  default = "windows_iis"
}
