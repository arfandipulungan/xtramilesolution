# Internet-facing ALB in public subnets, HTTPS only (TLS 1.3 policy), two target
# groups for CodeDeploy blue/green, AWS WAF in front, access logs to S3.
resource "aws_security_group" "alb" {
  name        = "${var.name}-alb"
  description = "ALB: HTTPS from the internet (or edge), HTTP only to redirect"
  vpc_id      = var.vpc_id
  tags        = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  for_each          = toset(var.allowed_ingress_cidrs)
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_ingress_rule" "http_redirect" {
  for_each          = var.enable_http_redirect ? toset(var.allowed_ingress_cidrs) : toset([])
  security_group_id = aws_security_group.alb.id
  description       = "HTTP, redirected to HTTPS"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "to_app" {
  security_group_id = aws_security_group.alb.id
  description       = "To app instances only"
  ip_protocol       = "tcp"
  from_port         = var.target_port
  to_port           = var.target_port
  cidr_ipv4         = var.vpc_cidr
}

resource "aws_lb" "this" {
  #checkov:skip=CKV2_AWS_76:Web ACL is owned by the platform/security account and includes AWSManagedRulesKnownBadInputsRuleSet (Log4j)
  name                       = var.name
  load_balancer_type         = "application"
  internal                   = false
  subnets                    = var.public_subnet_ids
  security_groups            = [aws_security_group.alb.id]
  drop_invalid_header_fields = true
  enable_deletion_protection = var.deletion_protection
  tags                       = var.tags

  access_logs {
    bucket  = var.access_log_bucket
    prefix  = "alb/${var.name}"
    enabled = true
  }
}

resource "aws_lb_target_group" "this" {
  #checkov:skip=CKV_AWS_378:TLS terminates at the ALB; ALB to instance traffic stays inside private subnets, restricted by security groups
  for_each = toset(["blue", "green"])

  name                 = "${var.name}-${each.key}"
  port                 = var.target_port
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  deregistration_delay = 30
  tags                 = var.tags

  health_check {
    path                = "/health"
    matcher             = "200"
    interval            = 15
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this["blue"].arn
  }

  lifecycle {
    # CodeDeploy flips the listener between blue and green during deployments.
    ignore_changes = [default_action]
  }
}

resource "aws_lb_listener" "http" {
  count             = var.enable_http_redirect ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_wafv2_web_acl_association" "this" {
  resource_arn = aws_lb.this.arn
  web_acl_arn  = var.waf_web_acl_arn
}
