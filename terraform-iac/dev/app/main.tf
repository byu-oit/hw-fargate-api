terraform {
  backend "s3" {
    bucket         = "terraform-state-storage-<account_number>"
    dynamodb_table = "terraform-state-lock-<account_number>"
    key            = "hello-world-api-dev/app.tfstate"
    region         = "us-west-2"
  }
}

provider "aws" {
  version = "~> 2.42"
  region  = "us-west-2"
}

variable "image_tag" {
  type = string
}

data "aws_ecr_repository" "my_ecr_repo" {
  name = "hello-world-api-dev"
}

module "acs" {
  source = "github.com/byu-oit/terraform-aws-acs-info?ref=v2.0.0"
}

module "my_fargate_api" {
  source                        = "github.com/byu-oit/terraform-aws-standard-fargate?ref=v2.0.0"
  app_name                      = "hello-world-api-dev"
  container_port                = 8080
  health_check_path             = "/health"
  codedeploy_test_listener_port = 4443
  task_policies                 = [aws_iam_policy.my_dynamo_policy.arn]
  hosted_zone                   = module.acs.route53_zone
  https_certificate_arn         = module.acs.certificate.arn
  public_subnet_ids             = module.acs.public_subnet_ids
  private_subnet_ids            = module.acs.private_subnet_ids
  vpc_id                        = module.acs.vpc.id
  codedeploy_service_role_arn   = module.acs.power_builder_role.arn
  role_permissions_boundary_arn = module.acs.role_permissions_boundary.arn

  primary_container_definition = {
    name  = "hello-world-api-dev"
    image = "${data.aws_ecr_repository.my_ecr_repo.repository_url}:${var.image_tag}"
    ports = [8080]
    environment_variables = {
      DYNAMO_TABLE_NAME = aws_dynamodb_table.my_dynamo_table.name
    }
    secrets = {
      "SOME_SECRET" = "/hello-world-api/dev/some-secret"
    }
  }

  autoscaling_config = {
    min_capacity = 1
    max_capacity = 2
  }

  codedeploy_lifecycle_hooks = {
    BeforeInstall         = null
    AfterInstall          = null
    AfterAllowTestTraffic = aws_lambda_function.test_lambda.function_name
    BeforeAllowTraffic    = null
    AfterAllowTraffic     = null
  }

  tags = {
    env              = "dev"
    data-sensitivity = "public"
    repo             = "https://github.com/byu-oit/hello-world-api"
  }
}

resource "aws_dynamodb_table" "my_dynamo_table" {
  name         = "hello-world-api-dev"
  hash_key     = "my_key_field"
  billing_mode = "PAY_PER_REQUEST"
  attribute {
    name = "my_key_field"
    type = "S"
  }

  tags = {
    env              = "dev"
    data-sensitivity = "public"
    repo             = "https://github.com/byu-oit/hello-world-api"
  }
}

resource "aws_iam_policy" "my_dynamo_policy" {
  name        = "hello-world-api-dynamo-dev"
  path        = "/"
  description = "Access to dynamo table"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:BatchGet*",
                "dynamodb:DescribeStream",
                "dynamodb:DescribeTable",
                "dynamodb:Get*",
                "dynamodb:Query",
                "dynamodb:Scan",
                "dynamodb:BatchWrite*",
                "dynamodb:Update*",
                "dynamodb:PutItem"
            ],
            "Resource": "${aws_dynamodb_table.my_dynamo_table.arn}"
        }
    ]
}
EOF
}

resource "aws_iam_role" "test_lambda" {
  name                 = "hello-world-api-deploy-test-dev"
  permissions_boundary = module.acs.role_permissions_boundary.arn

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "test_lambda" {
  filename         = "../../../tst/codedeploy-hooks/after-allow-test-traffic/lambda.zip"
  function_name    = "hello-world-api-deploy-test-dev"
  role             = aws_iam_role.test_lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs12.x"
  timeout          = 30
  source_code_hash = filebase64sha256("../../../tst/codedeploy-hooks/after-allow-test-traffic/lambda.zip")
}

resource "aws_iam_role_policy" "test_lambda" {
  name        = "hello-world-api-deploy-test-dev"
  role        = aws_iam_role.test_lambda.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    },
    {
      "Action": "codedeploy:PutLifecycleEventHookExecutionStatus",
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

output "url" {
  value = module.my_fargate_api.dns_record
}
