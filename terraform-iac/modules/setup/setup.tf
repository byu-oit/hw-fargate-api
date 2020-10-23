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

data "aws_iam_policy" "power_user" {
  name = "PowerUserPolicy"
}

data "aws_iam_user" "github_actions" {
  user_name = "GitHub-Actions"
}

resource "aws_iam_role" "deploy" {
  name = "${local.name}-deploy"
  permissions_boundary = data.aws_iam_policy.power_user.arn
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowIamUserAssumeRole",
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Principal": {"AWS": "${data.aws_iam_user.github_actions.arn}"},
        }
    ]
}
EOF
}

