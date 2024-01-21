resource "aws_ecr_repository" "main" {
  name = "${var.project_name}-${var.environment}-repo"
  tags = merge(local.tags, { Name = "${title(var.project_name)} ECR" })
}
