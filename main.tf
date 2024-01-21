locals {
    project_name = "{name}"
    aws_region = "{region}"
    certificate_arn   = "{arn}"
    app_port = {port}
    health_check_path = "/"
}


provider "aws" {
    shared_credentials_files = ["~/.aws/credentials"]
    shared_config_files = ["~/.aws/config"]
    profile = "{profile}"
    region = local.aws_region
}

terraform {
    backend "s3" {
        bucket = "{bucket}"
        key = "ecs/terraform.tfstate"
        region = "{region}"
        shared_credentials_files = ["~/.aws/credentials"]
        profile = "{profile}"
    }
}

module "ecs_prod" {
    source = "git@github.com:wonholim/ec2-fargate-tf.git//{Variable}"
    project_name = local.project_name
    aws_region = local.aws_region
    health_check_path = local.health_check_path
    app_port = local.app_port
    environment = "production"
    task_cpu = 512
    task_memory = 1024
}

module "ecs_dev" {
    source = "git@github.com:wonholim/ec2-fargate-tf.git//{Variable}"
    project_name = local.project_name
    aws_region = local.aws_region
    health_check_path = local.health_check_path
    app_port = local.app_port
    environment = "development"
    app_max_count = 2
}