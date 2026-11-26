terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Credentials come from the pipeline's OIDC role (aws-actions/configure-aws-credentials).
provider "aws" {
  region = "ap-southeast-2"
  default_tags {
    tags = { managed-by = "terraform" }
  }
}
