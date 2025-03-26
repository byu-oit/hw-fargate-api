env            = "stg"
aws_account_id = "977306314792"

# image_tag provided by pipeline (or user)
codedeploy_termination_wait_time = 0
deploy_test_postman_collection   = "../../.postman/hw-fargate-api.postman_collection.json"
deploy_test_postman_environment  = "../../.postman/stg-tst.postman_environment.json"
log_retention_days               = 1
