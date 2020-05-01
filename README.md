# hello-world-api
Example of creating and deploying an API with Docker and Terraform on AWS.

## Prerequisites

* Install [Terraform](https://www.terraform.io/downloads.html)
* Install the [awslogin](https://pypi.org/project/byu-awslogin/) CLI tool
* Login to a dev account (with awslogin)
* Ensure your account has a [Terraform State S3 Backend](https://github.com/byu-oit/terraform-aws-backend-s3) deployed.

## Setup
* Create a new repo from this template (you need your own repo so that you can push changes and have CodePipeline deploy them)
* Clone your new repo
```
git clone https://github.com/byu-oit/my-new-repo
```
* Checkout the dev branch
```
cd my-new-repo
git checkout -b dev
```
* Find all of the `.tf` files under `terraform-iac/dev/` and `terraform-iac/modules/`and:
  * replace `<account_number>` with your account number.
  * replace `hello-world-api` with the name of your repo.
* Commit/push your changes
```
git commit -am "update template with repo specific details" 
git push
```

## Deployment

### Deploy the "one time setup" resources

```
cd terraform-iac/dev/setup/
terraform init
terraform apply
```

In the AWS Console, see if you can find the resources from `setup.tf` (ECR, SSM Param).

### Deploy the pipeline

```
cd ../pipeline/
terraform init
terraform apply
```

In the AWS Console, find the CodePipeline. Look at the "details" of each stage as it is executing, to learn what the stage does.

See if you can find each of the resources from `pipeline.tf`.

### View the deployed application

Anytime after the `Terraform` phase succeeds:
```
cd ../app/
terraform init
terraform output
```

This will output a DNS Name. Enter this in a browser. It will probably return `503 Service Unavailable`. It takes some time for the ECS Tasks to spin up and for the ALB to recognize that they are healthy.

In the AWS Console, see if you can find the ECS Service and see the state of its ECS Tasks. Also see if you can find the ALB Target Group, and notice when Tasks are added to it.

> Note:
> 
> While Terraform creates the ECS Service, it doesn't actually spin up any ECS Tasks. This isn't Terraform's job. The ECS Service is responsible for ensuring that ECS Tasks are running.
> 
> Because of this, if the ECS Tasks fail to launch (due to bugs in the code causing the docker container to crash, for example), Terraform won't know anything about that. From Terraform's perspective, the deployment was successful.
> 
> These type of issues can often be tracked down by finding the Stopped ECS Tasks in the ECS Console, and looking at their logs or their container status.

Once the Tasks are running, you should be able to hit the app's URL and get a JSON response. Between `index.js` and `main.tf`, can you find what pieces are necessary to make this data available to the app?

In the AWS Console, see if you can find the other resources from `main.tf`.

### Push a change to your application

Make a small change to `index.js` (try adding a `console.log`, a simple key/value pair to the JSON response, or a new path). Commit and push this change to the `dev` branch.

```
git commit -am "try deploying a change"
git push
```

In the AWS Console, watch the CodePipeline deploy. The CodeDeploy stage is particularly interesting. Once CodeDeploy says that the Replacement tasks are serving traffic, hit your application in the browser and see if your change worked. If the service is broken, look at the stopped ECS Tasks in the ECS Console to see if you can figure out why.

> Note: 
>
> It's always best to test your changes locally before pushing to GitHub and AWS. Testing locally will significantly increase your productivity as you won't be constantly waiting for CodePipeline to deploy, just to discover bugs.
>
> You can either test locally inside Docker, or with Node directly on your computer. Whichever method you choose, you'll have to setup the environment variables that ECS makes available to your code when it runs in AWS. You can find these environment variables in `index.js` and `main.tf`.

## Learn what was built

By digging through the `.tf` files, you'll see what resources are being created. You should spend some time searching through the AWS Console for each of these resources. The goal is to start making connections between the Terraform syntax and the actual AWS resources that are created.

Several OIT created Terraform modules are used. You can look these modules up in our GitHub Organization. There you can see what resources each of these modules creates. You can look those up in the AWS Console too.
