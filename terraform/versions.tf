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

  # Backend local por defecto (ideal para inicio y pruebas)
  # Para migrar a backend remoto en S3 (recomendado en produccion para CI/CD):
  # backend "s3" {
  #   bucket         = "TU-BUCKET-TERRAFORM-STATE"
  #   key            = "lambda-layer/terraform.tfstate"
  #   region         = "us-east-2"
  #   dynamodb_table = "TU-TABLA-DYNAMODB-LOCKS"
  #   encrypt        = true
  # }
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
