output "base" {
  description = "<app>-<env>"
  value       = local.base
}

output "names" {
  description = "Resource names shared by Terraform and the deployment pipeline"
  value = merge({
    resource_group   = "rg-${local.base}"
    app_service      = "app-${local.base}"
    service_plan     = "asp-${local.base}"
    function_app     = "func-${local.base}"
    vm               = "vm-${local.base}"
    key_vault        = "kv${local.compact}"
    storage          = "st${local.compact}"
    log_analytics    = "log-${local.base}"
    app_insights     = "appi-${local.base}"
    vnet             = "vnet-${local.base}"
    vpc              = "vpc-${local.base}"
    alb              = "alb-${local.base}"
    asg              = "asg-${local.base}"
    rds              = "rds-${local.base}"
    codedeploy_app   = var.app
    codedeploy_group = local.base
  }, var.name_overrides)
}

output "tags" {
  description = "Standard tags for every resource"
  value       = local.tags
}
