terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Pass the bucket and key via the CLI runner, by using -backend-config options.
    # The key will be used to differentiate multiple development preview environments, based on the feature branch name.
    region         = "us-east-1"
    use_lockfile   = true
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1" # Northern Virginia
}
