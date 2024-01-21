resource "aws_codedeploy_app" "main" {
  compute_platform = "ECS"
  name             = "${var.project_name}-${var.environment}-deploy"
  tags             = merge(local.tags, { Name = "${title(var.project_name)} CodeDeploy App" })
}

resource "aws_codedeploy_deployment_group" "main" {
  app_name               = aws_codedeploy_app.main.name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = "${var.project_name}-${var.environment}-dg"
  service_role_arn       = aws_iam_role.code_deploy_role.arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout    = "CONTINUE_DEPLOYMENT"
      wait_time_in_minutes = 0
    }
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = var.termination_wait_time_in_minutes
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.main.name
    service_name = aws_ecs_service.main.name
  }

  load_balancer_info {
    target_group_pair_info {
      target_group {
        name = aws_alb_target_group.main.*.name[0]
      }
      target_group {
        name = aws_alb_target_group.main.*.name[1]
      }
      prod_traffic_route {
        listener_arns = [aws_alb_listener.main.arn]
      }
      # test_traffic_route {
      #   listener_arns = [aws_alb_listener.app_listener.arn]
      # }
    }
  }

  tags = merge(local.tags, { Name = "${title(var.project_name)} CodeDeploy Deployment Group" })
}
