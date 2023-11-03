variable "env" {
  type = string
}

variable "image_tag" {
  type = string
}

variable "codedeploy_termination_wait_time" {
  type = number
}

variable "deploy_test_postman_collection" {
  type = string
}

variable "deploy_test_postman_environment" {
  type = string
}

variable "log_retention_days" {
  type = number
}

locals {
  name = "hw-fargate-api"
  env  = var.env
}

data "aws_ecr_repository" "my_ecr_repo" {
  name = "${local.name}-${var.env}"
}

module "acs" {
  source = "github.com/byu-oit/terraform-aws-acs-info?ref=v4.0.0"
}

module "my_fargate_api" {
  source                        = "github.com/byu-oit/terraform-aws-fargate-api?ref=scaling"
  app_name                      = "${local.name}-${var.env}"
  container_port                = 8080
  health_check_path             = "/health"
  codedeploy_test_listener_port = 4443
  task_policies = [
    aws_iam_policy.my_dynamo_policy.arn,
    aws_iam_policy.my_s3_policy.arn
  ]

  hosted_zone                      = module.acs.route53_zone
  https_certificate_arn            = module.acs.certificate.arn
  public_subnet_ids                = module.acs.public_subnet_ids
  private_subnet_ids               = module.acs.private_subnet_ids
  vpc_id                           = module.acs.vpc.id
  codedeploy_service_role_arn      = module.acs.power_builder_role.arn
  codedeploy_termination_wait_time = var.codedeploy_termination_wait_time
  role_permissions_boundary_arn    = module.acs.role_permissions_boundary.arn
  log_retention_in_days            = var.log_retention_days

  primary_container_definition = {
    name  = "${local.name}-${var.env}"
    image = "${data.aws_ecr_repository.my_ecr_repo.repository_url}:${var.image_tag}"
    ports = [8080]
    environment_variables = {
      DYNAMO_TABLE_NAME = aws_dynamodb_table.my_dynamo_table.name,
      BUCKET_NAME       = aws_s3_bucket.my_s3_bucket.bucket
    }
    secrets = {
      "SOME_SECRET" = "/${local.name}/${var.env}/some-secret"
    }
    efs_volume_mounts = null
    ulimits           = null
  }

  autoscaling_config = {
    min_capacity  = 1
    max_capacity  = 8
    target_metric = "ECSServiceAverageCPUUtilization"
    target_value  = 30
  }
  task_cpu    = 256
  task_memory = 512

  codedeploy_lifecycle_hooks = {
    BeforeInstall         = null
    AfterInstall          = null
    AfterAllowTestTraffic = module.postman_test_lambda.lambda_function.function_name
    BeforeAllowTraffic    = null
    AfterAllowTraffic     = null
  }

  health_check_grace_period = 300
}

resource "aws_dynamodb_table" "my_dynamo_table" {
  name         = "${local.name}-${var.env}"
  hash_key     = "my_key_field"
  billing_mode = "PAY_PER_REQUEST"
  attribute {
    name = "my_key_field"
    type = "S"
  }
}

resource "aws_iam_policy" "my_dynamo_policy" {
  name        = "${local.name}-dynamo-${var.env}"
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

# -----------------------------------------------------------------------------
# START OF S3
# Note that in my_fargate_api, we also added a policy and environment variable
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "my_s3_bucket_logs" {
  bucket = "${local.name}-${var.env}-logs"
}

resource "aws_s3_bucket_lifecycle_configuration" "my_s3_bucket_logs" {
  bucket = aws_s3_bucket.my_s3_bucket_logs.id

  rule {
    id     = "AutoAbortFailedMultipartUpload"
    status = "Enabled"

    filter {
      prefix = ""
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 10
    }
  }

  rule {
    id = "ExpireOldLogs"
    expiration {
      days = var.log_retention_days
    }
    status = "Enabled"

    filter {
      prefix = ""
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "my_s3_bucket_logs" {
  bucket = aws_s3_bucket.my_s3_bucket_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "default_logs" {
  bucket                  = aws_s3_bucket.my_s3_bucket_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "my_s3_bucket" {
  bucket = "${local.name}-${var.env}"
}

resource "aws_s3_bucket_lifecycle_configuration" "my_s3_bucket" {
  bucket = aws_s3_bucket.my_s3_bucket.id

  rule {
    id     = "AutoAbortFailedMultipartUpload"
    status = "Enabled"

    filter {
      prefix = ""
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 10
    }
  }
}

resource "aws_s3_bucket_logging" "my_s3_bucket" {
  bucket = aws_s3_bucket.my_s3_bucket.id

  target_bucket = aws_s3_bucket.my_s3_bucket_logs.id
  target_prefix = "log/"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "my_s3_bucket" {
  bucket = aws_s3_bucket.my_s3_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "my_s3_bucket" {
  bucket = aws_s3_bucket.my_s3_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_s3_bucket_public_access_block" "default" {
  bucket                  = aws_s3_bucket.my_s3_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_policy" "my_s3_policy" {
  name        = "${local.name}-s3-${var.env}"
  description = "A policy to allow access to s3 to this bucket: ${aws_s3_bucket.my_s3_bucket.bucket}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": [
        "${aws_s3_bucket.my_s3_bucket.arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:DeleteObjectVersion",
        "s3:DeleteObject",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.my_s3_bucket.arn}/*"
      ]
    }
  ]
}
EOF
}

# -----------------------------------------------------------------------------
# END OF S3
# Note that in my_fargate_api, we also added a policy and environment variable
# -----------------------------------------------------------------------------

module "postman_test_lambda" {
  source   = "github.com/byu-oit/terraform-aws-postman-test-lambda?ref=v5.0.3"
  app_name = "${local.name}-${var.env}"
  postman_collections = [
    {
      collection  = var.deploy_test_postman_collection
      environment = var.deploy_test_postman_environment
    }
  ]
  role_permissions_boundary_arn = module.acs.role_permissions_boundary.arn
  log_retention_in_days         = var.log_retention_days
}

output "url" {
  value = module.my_fargate_api.dns_record.name
}

output "codedeploy_app_name" {
  value = module.my_fargate_api.codedeploy_deployment_group.app_name
}

output "codedeploy_deployment_group_name" {
  value = module.my_fargate_api.codedeploy_deployment_group.deployment_group_name
}

output "codedeploy_appspec_json_file" {
  value = module.my_fargate_api.codedeploy_appspec_json_file
}
