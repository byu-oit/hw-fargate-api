terraform {
  backend "s3" {
    bucket         = "terraform-state-storage-<account_number>"
    dynamodb_table = "terraform-state-lock-<account_number>"
    key            = "hello-world-api-dev/ecr.tfstate"
    region         = "us-west-2"
  }
}

provider "aws" {
  version = "~> 2.42"
  region  = "us-west-2"
}

module "my_ecr" {
  source               = "git@github.com:byu-oit/terraform-aws-ecr?ref=v1.0.1"
  name                 = "hello-world-api-dev"
  image_tag_mutability = "IMMUTABLE"

  lifecycle_policy = <<EOF
{
  "rules": [
    {
      "action": {
        "type": "expire"
      },
      "selection": {
        "countType": "imageCountMoreThan",
        "countNumber": 10,
        "tagStatus": "any"
      },
      "description": "Only keep 10 images",
      "rulePriority": 10
    }
  ]
}
EOF
}