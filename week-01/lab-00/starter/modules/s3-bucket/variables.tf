# S3 Bucket Module - Variables
# Define the inputs your module accepts

# TODO: Define the following variables:
# - bucket_name (string, required)
# - environment (string, required)
# - enable_versioning (bool, optional, default: true)
# - tags (map(string), optional, default: {})

variable "bucket_name" {
  description = "Base name for the S3 bucket"
  type        = string

  # TODO: Add validation to ensure bucket_name is at least 3 characters
}

# Add your other variables below...
