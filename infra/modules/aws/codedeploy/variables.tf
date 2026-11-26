variable "app_name" { type = string }
variable "deployment_group_name" { type = string }
variable "asg_name" { type = string }
variable "listener_arn" { type = string }
variable "alb_arn_suffix" { type = string }
variable "tags" { type = map(string) }

variable "target_group_names" {
  description = "Map with keys blue and green"
  type        = map(string)
}

variable "error_threshold" {
  description = "Target 5xx per minute that triggers rollback"
  type        = number
  default     = 10
}

variable "blue_termination_wait_minutes" {
  description = "Keep the old fleet this long after a successful deploy (fast manual rollback window)"
  type        = number
  default     = 60
}
