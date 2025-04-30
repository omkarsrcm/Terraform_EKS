terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {}
}

provider "aws" {
  region = local.aws_region
  assume_role {
    role_arn     = "arn:aws:iam::AccountID:role/terraform-executor-role"
    session_name = "TerraformSession"
  }
}
