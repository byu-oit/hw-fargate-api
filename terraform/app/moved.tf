# Feel free to delete this file once all environments have updated their state

moved {
  from = module.app.module.acs
  to   = module.acs
}

moved {
  from = module.app.module.my_fargate_api
  to   = module.my_fargate_api
}

moved {
  from = module.app.aws_dynamodb_table.my_dynamo_table
  to   = aws_dynamodb_table.my_dynamo_table
}

moved {
  from = module.app.aws_iam_policy.my_dynamo_policy
  to   = aws_iam_policy.my_dynamo_policy
}

moved {
  from = module.app.aws_s3_bucket.my_s3_bucket_logs
  to   = aws_s3_bucket.my_s3_bucket_logs
}

moved {
  from = module.app.aws_s3_bucket_lifecycle_configuration.my_s3_bucket_logs
  to   = aws_s3_bucket_lifecycle_configuration.my_s3_bucket_logs
}

moved {
  from = module.app.aws_s3_bucket_server_side_encryption_configuration.my_s3_bucket_logs
  to   = aws_s3_bucket_server_side_encryption_configuration.my_s3_bucket_logs
}

moved {
  from = module.app.aws_s3_bucket_public_access_block.default_logs
  to   = aws_s3_bucket_public_access_block.default_logs
}

moved {
  from = module.app.aws_s3_bucket.my_s3_bucket
  to   = aws_s3_bucket.my_s3_bucket
}

moved {
  from = module.app.aws_s3_bucket_lifecycle_configuration.my_s3_bucket
  to   = aws_s3_bucket_lifecycle_configuration.my_s3_bucket
}

moved {
  from = module.app.aws_s3_bucket_logging.my_s3_bucket
  to   = aws_s3_bucket_logging.my_s3_bucket
}

moved {
  from = module.app.aws_s3_bucket_server_side_encryption_configuration.my_s3_bucket
  to   = aws_s3_bucket_server_side_encryption_configuration.my_s3_bucket
}

moved {
  from = module.app.aws_s3_bucket_versioning.my_s3_bucket
  to   = aws_s3_bucket_versioning.my_s3_bucket
}

moved {
  from = module.app.aws_s3_bucket_public_access_block.default
  to   = aws_s3_bucket_public_access_block.default
}

moved {
  from = module.app.aws_iam_policy.my_s3_policy
  to   = aws_iam_policy.my_s3_policy
}

moved {
  from = module.app.module.postman_test_lambda
  to   = module.postman_test_lambda
}
