variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "address_space" { type = list(string) }
variable "tags" { type = map(string) }

variable "subnets" {
  description = "Subnets keyed by name, each with its own NSG rules"
  type = map(object({
    cidr       = string
    delegation = optional(string)
    nsg_rules = optional(list(object({
      name        = string
      priority    = number
      direction   = string
      access      = string
      protocol    = string
      port        = string
      source      = string
      destination = string
    })), [])
  }))
}
