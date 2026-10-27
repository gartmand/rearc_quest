# rearc_quest

This repository is a solution to rearc/quest, a repository containing a challenge from Rearc.

The subdirectory /app contains the original application, along with the Dockerfile used to containerize it.

# Infrastructure setup

## Prerequisites
* Terraform CLI (>= 1.11.0) and AWS CLI installed and configured
* An AWS account with appropriate permissions to create the resources
* An S3 bucket for Terraform state
* Docker Desktop (or similar) installed and configured
* AWS Profile logged in and active for CLI

## Setup 
In order to set up the infrastructure, do the following:
1. Open a terminal, and set `bucket_name` variable to the name of your S3 bucket for storing TF state
1. Set `github_org_or_user` and `github_repo` variables to the name of your GitHub Organization or User and the repository underneath it, respectively. For example, I would use `gartmand/rearc_quest`.
1. In infra/global/ecr, run `terraform init -backend-config="bucket=$bucket_name" `, then `terraform apply`. This will create an ECR repository called `rearc_quest`. Grab the output `repository_url` for use when pushing container images.
1. In infra/global/identity, run `terraform init -backend-config="bucket=$bucket_name" `, then `terraform apply`. This will create the global OIDC provider. Though currently unused,
    in the future this will allow for GitHub Actions to authenticate with AWS and deploy directly to the environments. It is also required for the production environment to create its linked OIDC role.
1. In app/, build the container image for the application by running `docker build -t <ECR_repository_url>:latest .`, then push the image to ECR with `docker push <ECR_repository_url>:latest`.
    * If you haven't already, you will need to either perform a Docker login to your ECR registry first using `aws ecr get-login-password | docker login --username AWS --password-stdin <account_id>.dkr.ecr.<region>.amazonaws.com`, or configure the [ECR credential helper](https://github.com/awslabs/amazon-ecr-credential-helper).
1. Create a secret called `rearc_quest/app-secret-code` in AWS Secrets Manager. You can seed it with any value for now.
1. In infra/environments/production, run `terraform init -backend-config="bucket=$bucket_name" `, then `terraform apply -var="github_org_or_user=$github_org_or_user" -var="github_repo=$github_repo"`. This will create the production environment infrastructure.
    * This will produce an output `ingress_paths`, which contains an HTTPS URL for the application.
1. Wait for the application to fully deploy; you can monitor this in Deployments within ECS.
1. Navigate to the root of the HTTPS URL from `ingress_paths`. Grab the passphrase shown here, and update the text value of the `rearc_quest/app-secret-code` secret in AWS Secrets Manager with it.
1. Run `terraform apply -var="github_org_or_user=$github_org_or_user" -var="github_repo=$github_repo"` again.
1. Once the apply finishes, force a deployment of the service within ECS to pick up the new secret value. Wait for the deployment to finish.
1. Navigate to the /secret_word endpoint of the application URL. You should see that the secret word has been accepted.

# Implementation journey
Please see [quest.md](/quest.md) for a summary of how the implementation journey went.
