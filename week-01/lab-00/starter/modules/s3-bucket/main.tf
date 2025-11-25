# S3 Bucket Module - Main Resources
# Create S3 bucket with versioning and encryption

# TODO: Implement the following resources:
# 1. aws_s3_bucket - The main bucket
# 2. aws_s3_bucket_versioning - Enable versioning
# 3. aws_s3_bucket_server_side_encryption_configuration - AES256 encryption

# Hint: Use locals to merge default tags with user-provided tags
# locals {
#   default_tags = {
#     Name        = var.bucket_name
#     Environment = var.environment
#     ManagedBy   = "terraform"
#     Module      = "s3-bucket"
#   }
#   all_tags = merge(local.default_tags, var.tags)
# }

# Your resources go here...
