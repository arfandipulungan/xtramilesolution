variable "repository" {
  description = "owner/repo allowed to use these identities"
  type        = string
}
variable "environment" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tags" { type = map(string) }

variable "subscription_id_scope" {
  description = "/subscriptions/<id> for this environment"
  type        = string
}

variable "state_container_id" {
  description = "Resource ID of the Terraform state blob container"
  type        = string
}

variable "deploy_scopes" {
  description = "Resource group IDs the deploy identity may deploy into"
  type        = list(string)
}
