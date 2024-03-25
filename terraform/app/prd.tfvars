env = "prd"

# image_tag provided by pipeline (or user)
codedeploy_termination_wait_time = 0 # You probably want to change this to 15 when your service is really prd
deploy_test_postman_collection   = "../../.postman/hw-fargate-api.postman_collection.json"
deploy_test_postman_environment  = "../../.postman/prd-tst.postman_environment.json"
log_retention_days               = 7
