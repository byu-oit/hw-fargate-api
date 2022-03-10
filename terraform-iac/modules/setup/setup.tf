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
  role_policy_arns               = [module.backend_s3_cicd.cicd_policy.arn, aws_iam_policy.gha.arn]
}

module "backend_s3_cicd" {
  source = "github.com/byu-oit/terraform-aws-backend-s3-cicd?ref=main"
  name   = "${local.name}-${var.env}"
  tags   = local.tags
}

resource "aws_iam_policy" "gha" {
  name   = "${local.name}-${var.env}-gha"
  tags   = local.tags
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:GetCallerIdentity",
                "ec2:DescribeAccountAttributes",
                "iam:ListAccountAliases",
                "ec2:DescribeVpcs",
                "ec2:DescribeSubnets",
                "iam:ListPolicies",
                "route53:ListHostedZones",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeRouteTables",
                "acm:ListCertificates"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:GetRole"
            ],
            "Resource": [
              "arn:aws:iam::977306314792:role/PowerBuilder",
              "arn:aws:iam::977306314792:role/PowerUser",
              "arn:aws:iam::977306314792:role/ReadOnly"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameter"
            ],
            "Resource": "arn:aws:ssm:us-west-2:977306314792:parameter/acsParameters"
        },
        {
            "Effect": "Allow",
            "Action": [
                "rds:DescribeDBSubnetGroups"
            ],
            "Resource": "arn:aws:rds:us-west-2:977306314792:subgrp:oit-oregon-dev-db-subnet-group"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeVpcAttribute"
            ],
            "Resource": "arn:aws:ec2:us-west-2:977306314792:vpc/vpc-03c6fb17e2731fe4a"
        },
        {
            "Effect": "Allow",
            "Action": [
                "route53:GetHostedZone"
            ],
            "Resource": "arn:aws:route53:::hostedzone/Z2PJEHHCKKSZK0"
        },
        {
            "Effect": "Allow",
            "Action": [
                "route53:ListTagsForResource"
            ],
            "Resource": [
                "arn:aws:route53:::healthcheck/*",
                "arn:aws:route53:::hostedzone/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "acm:DescribeCertificate"
            ],
            "Resource": [
              "arn:aws:acm:us-east-1:977306314792:certificate/a6eb1e68-48dc-40cf-941e-bfe02de50d4b",
              "arn:aws:acm:us-west-2:977306314792:certificate/c90213f0-8c56-4f62-8f2a-d382e4bcf1fd"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "acm:ListTagsForCertificate"
            ],
            "Resource": [
              "arn:aws:acm:us-east-1:977306314792:certificate/*",
              "arn:aws:acm:us-west-2:977306314792:certificate/*"
             ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:GetPolicy",
                "iam:GetPolicyVersion"
            ],
            "Resource": [
              "arn:aws:iam::977306314792:policy/iamRolePermissionBoundary",
              "arn:aws:iam::977306314792:policy/iamUserPermissionBoundary"
            ]
        }
    ]
}
EOF
}

output "gha_role_arn" {
  value = module.gha_role.iam_role_arn
}
