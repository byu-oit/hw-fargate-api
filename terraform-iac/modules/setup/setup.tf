variable "env" {
  type = string
}

variable "some_secret" {
  type = string
}

locals {
  name = "hw-fargate-api"
}

resource "aws_ssm_parameter" "some_secret" {
  name  = "/${local.name}/${var.env}/some-secret"
  type  = "SecureString"
  value = var.some_secret
}

module "my_ecr" {
  source = "github.com/byu-oit/terraform-aws-ecr?ref=v1.1.1"
  name   = "${local.name}-${var.env}"
}
