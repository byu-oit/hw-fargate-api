terraform {
  backend "s3" {
    bucket         = "terraform-state-storage-977306314792"
    dynamodb_table = "terraform-state-lock-977306314792"
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

module "my_fargate_api" {
  source              = "github.com/byu-oit/terraform-aws-standard-fargate?ref=v1.0.2"
  dept_abbr           = "oit"
  app_name            = "hello-world-api-dev"
  env                 = "dev"
  health_check_path   = "/health"
  image_port          = 8080
  container_image_url = "${data.aws_ecr_repository.my_ecr_repo.repository_url}:${var.image_tag}"
  vpn_to_campus       = false
  task_memory         = 1024
  task_cpu            = 512
  task_policies       = [aws_iam_policy.my_dynamo_policy.arn]

  container_env_variables = {
    DYNAMO_TABLE_NAME = aws_dynamodb_table.my_dynamo_table.name
  }

  container_secrets = {
    "SOME_SECRET" = "/hello-world-api/dev/some-secret"
  }

  tags = {
    env              = "dev"
    data-sensitivity = "public"
    repo             = "https://github.com/byu-oit/hello-world-api"
  }
}

////TODO: Switch to use a higher level module, maybe.
resource "aws_dynamodb_table" "my_dynamo_table" {
  name         = "hello-world-api-dev"
  hash_key     = "my_key_field"
  billing_mode = "PAY_PER_REQUEST"
  attribute {
    name = "my_key_field"
    type = "S"
  }
}
//TODO: Add tags

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

data "aws_ssm_parameter" "permissions_boundary" {
  name = "/acs/iam/iamRolePermissionBoundary"
}


resource "aws_iam_role" "iam_for_lambda" {
  name                 = "iam_for_lambda"
  permissions_boundary = data.aws_ssm_parameter.permissions_boundary.value

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
  filename      = "../../../tst/codedeploy-hooks/after-allow-test-traffic/lambda.zip"
  function_name = "hello-world-api-deploy-test-dev"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs8.10"
  depends_on    = [aws_iam_role_policy_attachment.lambda_logs]
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

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
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

output "url" {
  value = module.my_fargate_api.dns_record
}

// This is necessary for the pipeline to do a CodeDeploy deployment
output "appspec" {
  value = module.my_fargate_api.codedeploy_appspec_json
}
