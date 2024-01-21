/* -------------------------------------------------------------------------- */
/*                                     ECS                                    */
/* -------------------------------------------------------------------------- */

data "aws_iam_policy_document" "ecs_agent" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_agent" {
  name               = "${var.project_name}-${var.environment}-ecs-agent-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_agent.json
}

resource "aws_iam_instance_profile" "ecs_agent" {
  name = "${var.project_name}-${var.environment}-ecs-agent-profile"
  role = aws_iam_role.ecs_agent.name
}


data "aws_iam_policy_document" "ecs_task_assume_role_data" {
  version = "2012-10-17"

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.project_name}-${var.environment}-ecs-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_data.json
  tags               = merge(local.tags, { Name = "${title(var.project_name)} IAM Role" })
}

data "aws_iam_policy_document" "ecs_task_execution_role_data" {
  version = "2012-10-17"

  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecs_task_execution_policy" {
  name   = "${var.project_name}-${var.environment}-ecs-task-exec-policy"
  policy = data.aws_iam_policy_document.ecs_task_execution_role_data.json
  tags   = merge(local.tags, { Name = "${title(var.project_name)} IAM Policy" })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_execution_policy.arn
}

data "aws_iam_policy_document" "task_role_data" {
  statement {
    sid    = "AllowDescribeCluster"
    effect = "Allow"

    actions = ["ecs:DescribeClusters"]

    resources = [aws_ecs_cluster.main.arn]
  }
}

resource "aws_iam_role" "task_role" {
  name               = "${var.project_name}-${var.environment}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_data.json
  tags               = merge(local.tags, { Name = "${title(var.project_name)} IAM Role" })
}

resource "aws_iam_policy" "task_role_policy" {
  name   = aws_iam_role.task_role.name
  policy = data.aws_iam_policy_document.task_role_data.json
}

resource "aws_iam_role_policy_attachment" "task_role_policy_attach" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.task_role_policy.arn
}

/* -------------------------------------------------------------------------- */
/*                                CodePipeline                                */
/* -------------------------------------------------------------------------- */

data "aws_iam_policy_document" "codepipeline_assume_role" {
  version = "2012-10-17"

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "${var.project_name}-${var.environment}-codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_role.json
  tags               = merge(local.tags, { Name = "${title(var.project_name)} IAM Role" })
}

data "aws_iam_policy_document" "codepipeline_policy_data" {
  version = "2012-10-17"

  statement {
    sid    = "S3"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject",
      "s3:ListBucket",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowResources"
    effect = "Allow"

    actions = [
      "elasticloadbalancing:*",
      "autoscaling:*",
      "cloudwatch:*",
      "sns:*",
      "cloudformation:*",
      "rds:*",
      "sqs:*",
      "ecs:*",
      "ecr:*",
      "opsworks:*",
      "servicecatalog:*",
      "iam:PassRole"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowCodedepoloy"
    effect = "Allow"

    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetApplication",
      "codedeploy:GetApplicationRevision",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:RegisterApplicationRevision"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "codepipeline_policy" {
  name   = "${var.project_name}-${var.environment}-codepipeline-policy"
  policy = data.aws_iam_policy_document.codepipeline_policy_data.json
}

resource "aws_iam_role_policy_attachment" "codepipeline_role_attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}

/* -------------------------------------------------------------------------- */
/*                                 CodeDeploy                                 */
/* -------------------------------------------------------------------------- */

data "aws_iam_policy_document" "code_deploy_assume_role_data" {
  version = "2012-10-17"
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "code_deploy_policy_data" {
  version = "2012-10-17"

  statement {
    effect = "Allow"
    actions = [
      "ecs:DescribeServices",
      "ecs:CreateTaskSet",
      "ecs:UpdateServicePrimaryTaskSet",
      "ecs:DeleteTaskSet",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:ModifyRule",
      "lambda:InvokeFunction",
      "cloudwatch:DescribeAlarms",
      "sns:Publish",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "iam:PassRole"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "code_deploy_role" {
  name               = "${var.project_name}-${var.environment}-code-deploy-role"
  assume_role_policy = data.aws_iam_policy_document.code_deploy_assume_role_data.json
  tags               = merge(local.tags, { Name = "${title(var.project_name)} IAM Role" })
}

resource "aws_iam_policy" "code_deploy_policy" {
  name   = "${var.project_name}-${var.environment}-code_deploy_policy"
  policy = data.aws_iam_policy_document.code_deploy_policy_data.json
}

resource "aws_iam_role_policy_attachment" "code_deploy_role_attach" {
  role       = aws_iam_role.code_deploy_role.name
  policy_arn = aws_iam_policy.code_deploy_policy.arn
}
