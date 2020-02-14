# hello-world-api
Example of creating and deploying an API with Docker and Terraform on AWS.

## Prerequisites

* Install terraform
* Install byu_awslogin
* Login to a dev account (with awslogin)
* Ensure your account has an Terraform State S3 Backend deployed.

## Setup
* Create a new repo from this template (you need your own repo so that you can push changes and have CodePipeline deploy changes)
* Clone your new repo
```
git clone https://github.com/byu-oit/my-new-repo
```
* Checkout the dev branch
```
cd my-new-repo
git checkout dev
```
* Find all of the `.tf` files under `terraform-iac/dev/` and:
  * replace `<account_number>` with your account number.
  * replace `hello-world-api` with the name of your repo.
* Commit/push your changes
```
git commit -am "update template with repo specific details" 
git push
```

## Deployment

1. Deploy the "one time setup" resources
```
cd terraform-iac/dev/setup/
terraform init
terraform apply
```

2. Deploy the application (Optional. You can also just let the pipeline deploy it for you. But I usually deploy the app manually the first time. It's easier to troubleshoot deployment misconfigurations this way.)
```
cd ../app/
terraform init
terraform apply
```

3. Deploy the pipeline
```
cd ../pipeline/
terraform init
terraform apply
```