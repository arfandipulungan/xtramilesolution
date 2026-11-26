variable "repository" { type = string }
variable "environment" { type = string }
variable "subscription_id_scope" { type = string }
variable "state_container_id" { type = string }
variable "deploy_scopes" { type = list(string) }

variable "location" {
  type    = string
  default = "australiaeast"
}
