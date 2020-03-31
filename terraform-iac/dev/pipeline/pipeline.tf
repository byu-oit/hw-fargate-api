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

provider "github" {
  organization = "byu-oit"
  token        = module.acs.github_token
}

module "pipeline" {
  source = "../../modules/pipeline/"
  env    = "dev"
}
