terraform {
  required_version = "1.3.2"
  backend "s3" {
    bucket         = "terraform-state-storage-539738229445"
    dynamodb_table = "terraform-state-lock-539738229445"
    key            = "hw-fargate-api/cpy/app.tfstate"
    region         = "us-west-2"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

locals {
  env = "cpy"
}

provider "aws" {
  region = "us-west-2"

  default_tags {
    tags = {
      repo                   = "https://github.com/byu-oit/hw-fargate-api"
      data-sensitivity       = "public"
      env                    = local.env
      resource-creator-email = "GitHub-Actions"
    }
  }
}

variable "image_tag" {
  type = string
}

module "app" {
  source                           = "../../modules/app/"
  env                              = local.env
  image_tag                        = var.image_tag
  codedeploy_termination_wait_time = 15
  deploy_test_postman_collection   = "../../../.postman/hw-fargate-api.postman_collection.json"
  deploy_test_postman_environment  = "../../../.postman/cpy-tst.postman_environment.json"
  log_retention_days               = 7
}

output "url" {
  value = module.app.url
}

output "codedeploy_app_name" {
  value = module.app.codedeploy_app_name
}

output "codedeploy_deployment_group_name" {
  value = module.app.codedeploy_deployment_group_name
}

output "codedeploy_appspec_json_file" {
  value = module.app.codedeploy_appspec_json_file
}
