# Main configuration for Week 01 Lab 01
# Static Blog with Hugo and CloudFront

# TODO: Copy your S3 module from Lab 00 to ./modules/s3-bucket/
# Then update it to support website hosting (see README)

# TODO: Use your module to create a blog bucket
# module "blog_bucket" {
#   source = "./modules/s3-bucket"
#
#   bucket_name      = "${var.student_name}-blog"
#   environment      = var.environment
#   enable_website   = true
#   index_document   = "index.html"
#   error_document   = "404.html"
#
#   tags = {
#     Student      = var.student_name
#     AutoTeardown = "8h"
#   }
# }

# TODO: Create CloudFront distribution in cloudfront.tf
# See README for CloudFront configuration details
