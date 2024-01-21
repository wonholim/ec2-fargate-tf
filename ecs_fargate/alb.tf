locals {
  target_groups = ["blue", "green"]
}

resource "aws_alb" "main" {
  name            = "${var.project_name}-${var.environment}-alb"
  subnets         = aws_subnet.public.*.id
  security_groups = [aws_security_group.lb_sg.id]
  tags            = merge(local.tags, { Name = "${title(var.project_name)} ALB" })
}

resource "aws_alb_target_group" "main" {
  count = length(local.target_groups)
  name  = "${var.project_name}-${var.environment}-tg-${element(local.target_groups, count.index)}"
  tags  = merge(local.tags, { Name = "${title(var.project_name)} Target Group" })

  port        = 443
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    protocol = "HTTP"
    matcher  = 200
    path     = var.health_check_path
  }
}

resource "aws_alb_listener" "main" {
  load_balancer_arn = aws_alb.main.arn
  port              = 80
  protocol          = "HTTP"
  tags              = merge(local.tags, { Name = "${title(var.project_name)} Listener" })

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_alb_listener" "prod" {
  load_balancer_arn = aws_alb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn
  tags              = merge(local.tags, { Name = "${title(var.project_name)} Listener" })

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.main.1.arn
  }
}


resource "aws_alb_listener" "test" {
  load_balancer_arn = aws_alb.main.arn
  port              = 8443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn
  tags              = merge(local.tags, { Name = "${title(var.project_name)} Listener" })

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.main.1.arn
  }
}