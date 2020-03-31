terraform {
  backend "s3" {
    bucket         = "terraform-state-storage-<account_number>"
    dynamodb_table = "terraform-state-lock-<account_number>"
    key            = "hello-world-api-prd/app.tfstate"
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
  source    = "../../modules/app/"
  env       = "prd"
  image_tag = var.image_tag
}

output "url" {
  value = module.app.url
}
