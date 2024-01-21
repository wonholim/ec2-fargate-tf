resource "aws_codepipeline" "main" {
  name     = "${var.project_name}-${var.environment}-codepipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Artifact"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = 1
      run_order        = 1
      output_artifacts = ["SourceArtifact"]

      configuration = {
        S3Bucket             = aws_s3_bucket.codepipeline.bucket
        S3ObjectKey          = "artifact.zip"
        PollForSourceChanges = true
      }
    }

    action {
      name             = "DockerImage"
      category         = "Source"
      owner            = "AWS"
      provider         = "ECR"
      version          = 1
      run_order        = 1
      output_artifacts = ["ECRImage"]

      configuration = {
        ImageTag       = var.environment
        RepositoryName = aws_ecr_repository.main.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      input_artifacts = ["SourceArtifact", "ECRImage"]
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      version         = 1
      run_order       = 1

      configuration = {
        ApplicationName                = aws_codedeploy_app.main.name
        Image1ArtifactName             = "ECRImage"
        TaskDefinitionTemplateArtifact = "SourceArtifact"
        Image1ContainerName            = "IMAGE1_NAME"
        AppSpecTemplateArtifact        = "SourceArtifact"
        DeploymentGroupName            = aws_codedeploy_deployment_group.main.deployment_group_name
      }
    }
  }

  depends_on = [
    aws_s3_bucket.codepipeline
  ]

  tags = merge(local.tags, { Name = "${title(var.project_name)} CodePipeline" })
}
