variable "app" {
  description = "Short app name, e.g. customer-api"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}$", var.app))
    error_message = "app must be lowercase letters, digits and dashes (2-21 chars)."
  }
}

variable "environment" {
  description = "dev | staging | prod"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging or prod."
  }
}

variable "owner" {
  description = "Owning team, used for tagging and alert routing"
  type        = string
}

variable "cost_center" {
  description = "Cost center tag"
  type        = string
  default     = "product"
}

variable "extra_tags" {
  description = "Additional tags merged into the standard set"
  type        = map(string)
  default     = {}
}
