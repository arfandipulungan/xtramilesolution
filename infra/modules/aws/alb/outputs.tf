output "arn" { value = aws_lb.this.arn }
output "dns_name" { value = aws_lb.this.dns_name }
output "arn_suffix" { value = aws_lb.this.arn_suffix }
output "security_group_id" { value = aws_security_group.alb.id }
output "https_listener_arn" { value = aws_lb_listener.https.arn }
output "target_group_names" { value = { for k, tg in aws_lb_target_group.this : k => tg.name } }
output "target_group_arns" { value = { for k, tg in aws_lb_target_group.this : k => tg.arn } }
