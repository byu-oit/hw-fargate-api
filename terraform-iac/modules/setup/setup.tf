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
                "s3:ListBucket"
            ],
            "Resource": "arn:aws:s3:::terraform-state-storage-977306314792"
        },
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:PutItem",
                "dynamodb:GetItem",
                "dynamodb:DeleteItem"
            ],
            "Resource": "arn:aws:dynamodb:us-west-2:977306314792:table/terraform-state-lock-977306314792"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": "arn:aws:s3:::terraform-state-storage-977306314792/hw-fargate-api/dev/app.tfstate"
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
}

output "gha_role_arn" {
  value = aws_iam_role.gha.arn
}
