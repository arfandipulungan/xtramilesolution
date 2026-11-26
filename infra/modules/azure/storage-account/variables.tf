variable "name" {
  description = "Globally unique, 3-24 lowercase letters and digits"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.name))
    error_message = "Storage account names must be 3-24 lowercase letters or digits."
  }
}
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "private_endpoint_subnet_id" { type = string }
variable "log_analytics_workspace_id" { type = string }
variable "tags" { type = map(string) }

variable "replication_type" {
  description = "ZRS in prod for zone resilience, LRS acceptable in dev"
  type        = string
  default     = "ZRS"
}

variable "containers" {
  type    = list(string)
  default = []
}

variable "private_endpoint_subresources" {
  description = "Private endpoints to create: blob, queue, table, file"
  type        = list(string)
  default     = ["blob"]
}
