output "alb_dns_name" { value = module.alb.dns_name }
output "artifact_bucket" { value = module.artifact_bucket.id }
output "codedeploy_app" { value = module.codedeploy.app_name }
output "codedeploy_group" { value = module.codedeploy.deployment_group_name }
output "db_endpoint" { value = module.db.endpoint }
