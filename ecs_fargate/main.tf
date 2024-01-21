locals {
  tags = {
    Owner       = "${title(var.owner)}"
    Environment = "${title(var.environment)}"
    Project     = "${title(var.project_name)}"
  }
}

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-cluster"
  tags = merge(local.tags, { Name = "${title(var.project_name)} ECS Cluster" })
}


resource "aws_ecs_task_definition" "main" {
  family                   = "${var.project_name}-${var.environment}-task"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  container_definitions    = <<DEFINITION
[
  {
    "cpu": ${var.task_cpu},
    "memory": ${var.task_memory},
    "image": "${aws_ecr_repository.main.repository_url}",
    "name": "${var.project_name}-${var.environment}-container",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "containerPort": ${var.app_port},
        "hostPort": ${var.app_port},
        "protocol": "tcp"
      }
    ],
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/${var.project_name}-${var.environment}",
          "awslogs-region": "${var.aws_region}",
          "awslogs-stream-prefix": "ecs"
        }
    }
  }
]
DEFINITION
  tags                     = merge(local.tags, { Name = "${title(var.project_name)} ECS Task Definition" })
}

resource "aws_ecs_service" "main" {
  name                              = "${var.project_name}-${var.environment}-service"
  cluster                           = aws_ecs_cluster.main.id
  task_definition                   = aws_ecs_task_definition.main.arn
  desired_count                     = var.app_count
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = var.health_check_grace_period_seconds

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  network_configuration {
    security_groups  = [aws_security_group.ecs_sg.id]
    subnets          = aws_subnet.private.*.id
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.main.1.arn
    container_name   = "${var.project_name}-${var.environment}-container"
    container_port   = var.app_port
  }

  depends_on = [
    aws_alb_listener.main
  ]

  tags = merge(local.tags, { Name = "${title(var.project_name)} ECS Service" })
}
