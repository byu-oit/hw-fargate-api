variable "env" {
  type = "string"
}

locals {
  name   = "hello-world-api"
  branch = var.env == "prd" ? "master" : var.env
}

module "acs" {
  source = "github.com/byu-oit/terraform-aws-acs-info?ref=v2.0.0"
}

module "my_codepipeline" {
  source                        = "github.com/byu-oit/terraform-aws-fargate-codepipeline?ref=v0.1.0"
  pipeline_name                 = "${local.name}-${var.env}"
  role_permissions_boundary_arn = module.acs.role_permissions_boundary.arn
  power_builder_role_arn        = module.acs.power_builder_role.arn

  required_tags = {
    env              = var.env
    data-sensitivity = "public"
  }

  //Source
  source_github_owner  = "byu-oit"
  source_github_repo   = local.name
  source_github_branch = local.branch
  source_github_token  = module.acs.github_token

  //Build
  # use buildspec.yml from source (default)

  //Deploy
  deploy_terraform_application_path = "./terraform-iac/${var.env}/app/"
  deploy_code_deploy_config = {
    ApplicationName     = "${local.name}-${var.env}-codedeploy"
    DeploymentGroupName = "${local.name}-${var.env}-deployment-group"
  }
}