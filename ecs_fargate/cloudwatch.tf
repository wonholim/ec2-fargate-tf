/* -------------------------------------------------------------------------- */
/*                                   Metrics                                  */
/* -------------------------------------------------------------------------- */

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project_name}-${var.environment}-cpu-utilization-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = "80"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "3"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.main.name
  }

  alarm_actions = [aws_appautoscaling_policy.up.arn]
  tags          = merge(local.tags, { Name = "${title(var.project_name)} CW Metric Alarm" })
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.project_name}-${var.environment}-cpu-utilization-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  threshold           = "30"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "3"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.main.name
  }

  alarm_actions = [aws_appautoscaling_policy.down.arn]
  tags          = merge(local.tags, { Name = "${title(var.project_name)} CW Metric Alarm" })
}


/* -------------------------------------------------------------------------- */
/*                                    Logs                                    */
/* -------------------------------------------------------------------------- */

resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/${var.project_name}-${var.environment}"
  retention_in_days = 30
  tags              = merge(local.tags, { Name = "${title(var.project_name)} CW Logs" })
}

resource "aws_cloudwatch_log_stream" "main_log_stream" {
  name           = "${var.project_name}-${var.environment}-log-stream"
  log_group_name = aws_cloudwatch_log_group.main.name
}
