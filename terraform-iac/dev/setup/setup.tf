terraform {
  backend "s3" {
    bucket         = "terraform-state-storage-977306314792"
    dynamodb_table = "terraform-state-lock-977306314792"
    key            = "hello-world-api-dev/setup.tfstate"
    region         = "us-west-2"
  }
}

provider "aws" {
  version = "~> 2.42"
  region  = "us-west-2"
}

variable "some_secret" {
  type        = string
  description = "Some secret string that will be stored in SSM and mounted into the Fargate Tasks as an environment variable"
}

resource "aws_ssm_parameter" "some_secret" {
  name  = "/hello-world-api/dev/some-secret"
  type  = "SecureString"
  value = var.some_secret
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
