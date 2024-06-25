terraform {
  required_version = "~> 1.8"
  backend "s3" {
    bucket         = "terraform-state-storage-${var.aws_account_id}"
    dynamodb_table = "terraform-state-lock-${var.aws_account_id}"
    key            = "${local.name}/${var.env}/setup.tfstate"
    encrypt        = true
    region         = "us-west-2"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.55"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "aws" {
  region = "us-west-2"

  allowed_account_ids = [var.aws_account_id]

  default_tags {
    tags = {
      app                    = local.name
      repo                   = "https://github.com/${local.gh_org}/${local.gh_repo}"
      data-sensitivity       = "public"
      env                    = var.env
      resource-creator-email = "GitHub-Actions"
    }
  }
}

variable "env" {
  type        = string
  description = "Environment: dev, stg, cpy, or prd"
}

variable "aws_account_id" {
  type        = string
  description = "The 12-digit number that uniquely identifies an AWS account."
}

variable "some_secret" {
  type        = string
  description = "Some secret string that will be stored in SSM and mounted into the Fargate Tasks as an environment variable"
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

module "gha_role" {
  source                         = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                        = "5.39.1"
  create_role                    = true
  role_name                      = "${local.name}-${var.env}-gha"
  provider_url                   = module.acs.github_oidc_provider.url
  role_permissions_boundary_arn  = module.acs.role_permissions_boundary.arn
  role_policy_arns               = module.acs.power_builder_policies[*].arn
  oidc_fully_qualified_audiences = ["sts.amazonaws.com"]
  oidc_subjects_with_wildcards   = ["repo:${local.gh_org}/${local.gh_repo}:*"]
}

