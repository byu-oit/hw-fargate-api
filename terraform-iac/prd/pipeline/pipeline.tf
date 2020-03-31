terraform {
  backend "s3" {
    bucket         = "terraform-state-storage-<account_number>"
    dynamodb_table = "terraform-state-lock-<account_number>"
    key            = "hello-world-api-prd/pipeline.tfstate"
    region         = "us-west-2"
  }
}

provider "aws" {
  version = "~> 2.42"
  region  = "us-west-2"
}

provider "github" {
  organization = "byu-oit"
  token        = module.acs.github_token
}

module "pipeline" {
  source = "../../modules/pipeline/"
  env    = "prd"
}
