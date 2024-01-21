resource "aws_launch_template" "main" {
  name_prefix            = "${var.project_name}-${var.environment}-"
  vpc_security_group_ids = [aws_security_group.ecs_sg.id, aws_security_group.lb_sg.id]
  image_id               = var.ami
  instance_type          = var.instance_type
  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_agent.name
  }
  user_data  = base64encode("#!/bin/bash\necho ECS_CLUSTER=${aws_ecs_cluster.main.name} > /etc/ecs/ecs.config")
  depends_on = [aws_security_group.lb_sg, aws_security_group.ecs_sg, aws_iam_instance_profile.ecs_agent]
  tags       = merge(local.tags, { Name = "${title(var.project_name)} Launch Template" })
}

resource "aws_autoscaling_group" "main" {
  name                      = "${var.project_name}-${var.environment}-asg"
  vpc_zone_identifier       = aws_subnet.public.*.id
  min_size                  = var.app_min_count
  max_size                  = var.app_max_count
  desired_capacity          = var.app_count
  health_check_grace_period = var.health_check_grace_period_seconds
  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }
  depends_on = [aws_subnet.public]
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.project_name}-${var.environment}-asg-scale-down"
  autoscaling_group_name = aws_autoscaling_group.main.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 120
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.project_name}-${var.environment}-asg-scale-up"
  autoscaling_group_name = aws_autoscaling_group.main.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 120
}
