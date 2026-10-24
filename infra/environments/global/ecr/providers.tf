terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.23.0"
    }
  }

  # Pass the bucket via the CLI runner, by using -backend-config options.
  backend "s3" {
    key          = "global/ecr.tfstate"
    region       = "us-east-1" # Northern Virginia
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = "us-east-1" # Northern Virginia
}
