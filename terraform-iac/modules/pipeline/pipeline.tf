variable "env" {
  type = string
}

variable "role_permissions_boundary_arn" {
  type = string
}

variable "power_builder_role_arn" {
  type = string
}

variable "github_token" {
  type = string
}

locals {
  name   = "hello-world-api"
  branch = var.env == "prd" ? "master" : var.env
}

module "my_codepipeline" {
  source                        = "github.com/byu-oit/terraform-aws-fargate-codepipeline?ref=v0.1.0"
  pipeline_name                 = "${local.name}-${var.env}"
  role_permissions_boundary_arn = var.role_permissions_boundary_arn
  power_builder_role_arn        = var.power_builder_role_arn

  required_tags = {
    env              = var.env
    data-sensitivity = "public"
  }

  //Source
  source_github_owner  = "byu-oit"
  source_github_repo   = local.name
  source_github_branch = local.branch
  source_github_token  = var.github_token

  //Build
  # use buildspec.yml from source (default)
  build_env_variables = {
    ENV : var.env
  }

  //Deploy
  deploy_terraform_application_path = "./terraform-iac/${var.env}/app/"
  deploy_code_deploy_config = {
    ApplicationName     = "${local.name}-${var.env}-codedeploy"
    DeploymentGroupName = "${local.name}-${var.env}-deployment-group"
  }
}