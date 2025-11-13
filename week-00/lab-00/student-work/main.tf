# Terraform block - defines version requirements
terraform {
  required_version = ">= 1.9.0" # Minimum version needed for S3 native locking

  required_providers {
    aws = {
      source  = "hashicorp/aws" # Where to download the AWS provider
      version = "~> 5.0"        # Use any 5.x version (but not 6.0)
    }
  }
  backend "s3" {
    bucket       = "terraform-state-197005419426" # Replace with your bucket name
    key          = "week-00/lab-00/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true # Native S3 locking (Terraform 1.9+)
  }
}

# Provider block - configures AWS
provider "aws" {
  region = "us-east-1" # AWS region where resources will be created
}

# Resource block - creates an S3 bucket
resource "aws_s3_bucket" "test_bucket" {
  bucket = "terraform-lab-00-jlgore" # Replace with your GitHub username

  tags = {
    Name         = "Lab 0 Test Bucket"
    Environment  = "Learning"
    ManagedBy    = "Terraform"
    Student      = "jlgore" # Replace with your GitHub username
    AutoTeardown = "8h"
  }
}

resource "aws_s3_bucket_versioning" "test_bucket_versioning" {
  bucket = aws_s3_bucket.test_bucket.id # Reference to our bucket

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "test_bucket_encryption" {
  bucket = aws_s3_bucket.test_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" # AWS managed encryption
    }
  }
}
