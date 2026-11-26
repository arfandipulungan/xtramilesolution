variable "name" { type = string }
variable "app" { type = string }
variable "vpc_id" { type = string }
variable "app_subnet_ids" { type = list(string) }
variable "alb_security_group_id" { type = string }
variable "initial_target_group_arn" { type = string }
variable "artifact_bucket_arn" { type = string }
variable "kms_key_arn" { type = string }
variable "tags" { type = map(string) }

variable "ami_id" {
  description = "Hardened golden AMI (Packer + Ansible, scanned before use)"
  type        = string
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "app_port" {
  type    = number
  default = 5000
}

variable "root_volume_gb" {
  type    = number
  default = 30
}

variable "min_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 4
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "secret_arns" {
  description = "Secrets Manager ARNs this app may read"
  type        = list(string)
}

variable "ansible_group" {
  description = "Tag value used by the Ansible dynamic inventory"
  type        = string
  default     = "linux_app"
}

variable "user_data_base64" {
  type    = string
  default = null
}
