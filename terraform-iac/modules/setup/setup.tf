variable "env" {
  type = string
}

variable "some_secret" {
  type = string
}

locals {
  name = "hw-fargate-api"
  tags = {
    env              = var.env
    data-sensitivity = "public"
    repo             = "https://github.com/byu-oit/${local.name}"
  }
}

module "acs" {
  source = "github.com/byu-oit/terraform-aws-acs-info?ref=gha-oidc"
  #source = "github.com/byu-oit/terraform-aws-acs-info?ref=v3.5.0"
}

resource "aws_ssm_parameter" "some_secret" {
  name  = "/${local.name}/${var.env}/some-secret"
  type  = "SecureString"
  value = var.some_secret
  tags  = local.tags
}

module "my_ecr" {
  source = "github.com/byu-oit/terraform-aws-ecr?ref=v2.0.1"
  name   = "${local.name}-${var.env}"
  tags   = local.tags
}

resource "aws_iam_role" "gha" {
  name                 = "${local.name}-${var.env}-gha"
  permissions_boundary = module.acs.role_permissions_boundary.arn
  assume_role_policy   = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"Federated": "${module.acs.github_oidc_arn}"},
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringLike": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:byu-oit/${local.name}:*"
        }
      }
    }
  ]
}
EOF
  inline_policy {
    name   = "deploy-permissions"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
              "acm:*",
              "dynamodb:*",
              "ec2:*",
              "ecr:*",
              "iam:*",
              "rds:*",
              "route53:*",
              "s3:*",
              "ssm:*",
              "sts:*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
  }
}

output "gha_role_arn" {
  value = aws_iam_role.gha.arn
}
