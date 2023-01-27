variable "env" {
  type = string
}

variable "some_secret" {
  type = string
}

locals {
  name    = "hw-fargate-api"
  gh_org  = "byu-oit"
  gh_repo = "hw-fargate-api"
}

module "acs" {
  source = "github.com/byu-oit/terraform-aws-acs-info?ref=v4.0.0"
}

resource "aws_ssm_parameter" "some_secret" {
  name  = "/${local.name}/${var.env}/some-secret"
  type  = "SecureString"
  value = var.some_secret
}

module "my_ecr" {
  source = "github.com/byu-oit/terraform-aws-ecr?ref=v2.0.1"
  name   = "${local.name}-${var.env}"
}

resource "aws_iam_role" "gha" {
  name                 = "${local.name}-${var.env}-gha"
  permissions_boundary = module.acs.role_permissions_boundary.arn
  managed_policy_arns  = module.acs.power_builder_policies[*].arn
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.acs.github_oidc_provider.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "${module.acs.github_oidc_provider.url}:sub" = "repo:${local.gh_org}/${local.gh_repo}:*"
          }
          StringEquals = {
            "${module.acs.github_oidc_provider.url}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

