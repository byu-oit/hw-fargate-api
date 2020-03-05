terraform {
  backend "s3" {
    bucket         = "terraform-state-storage-<account_number>"
    dynamodb_table = "terraform-state-lock-<account_number>"
    key            = "hello-world-api-dev/pipeline.tfstate"
    region         = "us-west-2"
  }
}

provider "aws" {
  version = "~> 2.42"
  region  = "us-west-2"
}

module "acs" {
  source    = "github.com/byu-oit/terraform-aws-acs-info?ref=v1.2.2"
  dept_abbr = "oit"
  env       = "dev"
}

provider "github" {
  organization = "byu-oit"
  token        = module.acs.github_token
}

module "buildspec" {
  source        = "github.com/byu-oit/terraform-aws-basic-codebuild-helper?ref=v0.0.2"
  ecr_repo_name = "hello-world-api-dev"
  artifacts     = ["./terraform-iac/dev/app/*"]
  pre_script    = ["cd src", "npm install"]
}

module "my_codepipeline" {
  source                        = "github.com/byu-oit/terraform-aws-fargate-codepipeline?ref=v0.0.7"
  pipeline_name                 = "hello-world-api-dev"
  acs_env                       = "dev"
  role_permissions_boundary_arn = module.acs.role_permissions_boundary.arn
  power_builder_role_arn        = module.acs.power_builder_role.arn

  required_tags = {
    env              = "dev"
    data-sensitivity = "public"
  }

  //Source
  source_github_repo   = "hello-world-api"
  source_github_branch = "dev"
  source_github_token  = module.acs.github_token

  //Build
  build_buildspec = module.buildspec.script

  //Deploy
  deploy_terraform_application_path = "./terraform-iac/dev/app/"
  deploy_code_deploy_config = {
    ApplicationName     = "hello-world-api-dev-codedeploy"
    DeploymentGroupName = "hello-world-api-dev-deployment-group"
  }
}
