terraform {
  required_version = "0.12.26"
  backend "s3" {
    bucket         = "terraform-state-storage-977306314792"
    dynamodb_table = "terraform-state-lock-977306314792"
    key            = "hw-fargate-api-dev/app.tfstate"
    region         = "us-west-2"
  }
}

provider "aws" {
  version = "~> 2.42"
  region  = "us-west-2"
}

variable "image_tag" {
  type = string
}

module "app" {
  source                           = "../../modules/app/"
  env                              = "dev"
  image_tag                        = var.image_tag
  codedeploy_termination_wait_time = 0
  deploy_test_postman_collection   = "../../../.postman/hw-fargate-api.postman_collection.json"
  deploy_test_postman_environment  = "../../../.postman/dev-tst.postman_environment.json"
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
