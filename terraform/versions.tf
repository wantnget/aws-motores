terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  backend "s3" {
    bucket         = "motor-aws-tfstate-532918216426"
    key            = "lambda-layer/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "motor-aws-tfstate-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "motor-aws"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}