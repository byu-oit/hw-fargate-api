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

module "gha_role" {
  source                         = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                        = "4.13.2"
  create_role                    = true
  role_name                      = "${local.name}-${var.env}-gha"
  role_permissions_boundary_arn  = module.acs.role_permissions_boundary.arn
  tags                           = local.tags
  provider_url                   = "token.actions.githubusercontent.com"
  oidc_fully_qualified_audiences = ["sts.amazonaws.com"]
  oidc_subjects_with_wildcards   = ["repo:byu-oit/${local.name}:*"]
  number_of_role_policy_arns     = 2
  role_policy_arns = [
    module.backend_s3_cicd.cicd_policy.arn,
    module.acs_info_cicd.cicd_policy.arn
  ]
}

module "backend_s3_cicd" {
  source = "github.com/byu-oit/terraform-aws-backend-s3-cicd?ref=main"
  name   = "${local.name}-${var.env}"
  tags   = local.tags
}

module "acs_info_cicd" {
  source = "github.com/byu-oit/terraform-aws-acs-info-cicd?ref=main"
  name   = "${local.name}-${var.env}"
  tags   = local.tags
}

output "gha_role_arn" {
  value = module.gha_role.iam_role_arn
}
