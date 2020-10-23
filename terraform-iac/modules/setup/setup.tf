variable "env" {
  type = string
}

variable "some_secret" {
  type = string
}

locals {
  name = "hw-fargate-api"
}

resource "aws_ssm_parameter" "some_secret" {
  name  = "/${local.name}/${var.env}/some-secret"
  type  = "SecureString"
  value = var.some_secret
}

module "my_ecr" {
  source = "github.com/byu-oit/terraform-aws-ecr?ref=v1.1.1"
  name   = "${local.name}-${var.env}"
}

data "aws_iam_user" "github_actions" {
  user_name = "GitHub-Actions"
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "deploy" {
  name                 = "${local.name}-deploy"
  permissions_boundary = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/PowerUserPolicy"
  assume_role_policy   = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowIamUserAssumeRole",
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Principal": {"AWS": "${data.aws_iam_user.github_actions.arn}"}
        }
    ]
}
EOF
}

