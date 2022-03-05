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
  source = "github.com/byu-oit/terraform-aws-acs-info?ref=v3.4.0"
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

data "aws_ssm_parameter" "gha_oidc_arn" {
  name = "/acs/git/oidc-arn"
}

resource "aws_iam_role" "gha" {
  name                 = "${local.name}-${var.env}-gha"
  permissions_boundary = module.acs.role_permissions_boundary.arn
  managed_policy_arns  = ["arn:aws:iam::aws:policy/AdministratorAccess"]
  assume_role_policy   = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"Federated": "${data.aws_ssm_parameter.gha_oidc_arn.value}"},
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "ForAllValues:StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:byu-oit/${local.name}:*"
        }
      }
    }
  ]
}
EOF
}

output "gha_role_arn" {
  value = aws_iam_role.gha.arn
}
