terraform {
  backend "s3" {
    bucket         = "terraform-state-storage-977306314792"
    dynamodb_table = "terraform-state-lock-977306314792"
    key            = "hello-world-api-dev/pipeline.tfstate"
    region         = "us-west-2"
  }
}

provider "aws" {
  version = "~> 2.42"
  region  = "us-west-2"
}

module "acs" {
  source = "github.com/byu-oit/terraform-aws-acs-info?ref=v2.0.0"
}

provider "github" {
  organization = "byu-oit"
  token        = module.acs.github_token
}

module "my_codepipeline" {
  source                        = "github.com/byu-oit/terraform-aws-fargate-codepipeline?ref=v0.1.0"
  pipeline_name                 = "hello-world-api-dev"
  role_permissions_boundary_arn = module.acs.role_permissions_boundary.arn
  power_builder_role_arn        = module.acs.power_builder_role.arn

  required_tags = {
    env              = "dev"
    data-sensitivity = "public"
  }

  //Source
  source_github_owner  = "byu-oit"
  source_github_repo   = "hello-world-api"
  source_github_branch = "dev"
  source_github_token  = module.acs.github_token

  //Build
  # use buildspec.yml from source (default)

  //Deploy
  deploy_terraform_application_path = "./terraform-iac/dev/app/"
  deploy_code_deploy_config = {
    ApplicationName     = "hello-world-api-dev-codedeploy"
    DeploymentGroupName = "hello-world-api-dev-deployment-group"
  }
}
