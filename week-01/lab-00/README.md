# Week 01 - Lab 00: Terraform Modules and Testing

## Overview

In this lab, you'll take the S3 bucket code you wrote in Week 00 and refactor it into a **reusable Terraform module**. You'll then write **Terraform native tests** to validate your module works correctly.

## Learning Objectives

By the end of this lab, you will be able to:

- Understand the DRY (Don't Repeat Yourself) principle in Infrastructure as Code
- Create a reusable Terraform module with proper structure
- Define module inputs (variables) and outputs
- Write Terraform native tests using `.tftest.hcl` files
- Run tests with `terraform test`
- Understand the difference between unit tests and integration tests

## Prerequisites

- Completed Week 00 labs
- Terraform >= 1.9.0 (includes native testing support)
- AWS credentials configured
- GitHub Codespace or local development environment

## Background: Why Modules?

In Week 00, you created an S3 bucket with versioning and encryption. What if you need to create 10 more buckets with the same configuration? Copy-paste leads to:

- **Maintenance nightmare**: Change one thing, update 10 files
- **Inconsistency**: Each copy might drift slightly
- **Bugs**: Easy to miss updates in some copies

**Modules solve this** by packaging your Terraform code into a reusable unit:

```hcl
# Instead of copying 50 lines of S3 configuration...
module "logs_bucket" {
  source      = "./modules/s3-bucket"
  bucket_name = "my-app-logs"
  environment = "prod"
}

module "assets_bucket" {
  source      = "./modules/s3-bucket"
  bucket_name = "my-app-assets"
  environment = "prod"
}
```

## Background: Why Testing?

You wouldn't deploy application code without tests. Why deploy infrastructure without them?

Terraform 1.6+ includes **native testing** with `.tftest.hcl` files:

```hcl
# tests/s3_bucket.tftest.hcl
run "bucket_creates_successfully" {
  command = plan

  assert {
    condition     = aws_s3_bucket.this.bucket != ""
    error_message = "Bucket name should not be empty"
  }
}
```

## Lab Tasks

### Part 1: Create the Module Structure (40 points)

Create a reusable S3 bucket module in `student-work/modules/s3-bucket/`:

```
student-work/
├── main.tf                 # Uses your module
├── outputs.tf              # Root outputs
├── variables.tf            # Root variables
├── providers.tf            # AWS provider config
├── modules/
│   └── s3-bucket/
│       ├── main.tf         # S3 resources
│       ├── variables.tf    # Module inputs
│       └── outputs.tf      # Module outputs
└── tests/
    └── s3_bucket.tftest.hcl
```

#### Module Requirements

Your `modules/s3-bucket/` module must:

1. **Accept these input variables:**
   - `bucket_name` (string, required) - Base name for the bucket
   - `environment` (string, required) - Environment tag (dev/staging/prod)
   - `enable_versioning` (bool, optional, default: true)
   - `tags` (map(string), optional) - Additional tags to merge

2. **Create these resources:**
   - `aws_s3_bucket` - The bucket itself
   - `aws_s3_bucket_versioning` - Versioning configuration
   - `aws_s3_bucket_server_side_encryption_configuration` - AES256 encryption

3. **Output these values:**
   - `bucket_id` - The bucket name
   - `bucket_arn` - The bucket ARN
   - `bucket_region` - The bucket region

4. **Apply these tags to all resources:**
   - `Name` - The bucket name
   - `Environment` - From variable
   - `ManagedBy` - "terraform"
   - `Module` - "s3-bucket"
   - Plus any additional tags passed in

### Part 2: Use the Module (20 points)

In your root `main.tf`, use your module to create a bucket:

```hcl
module "lab_bucket" {
  source = "./modules/s3-bucket"

  bucket_name = "yourname-week01-lab00"
  environment = "dev"

  tags = {
    Student      = "your-github-username"
    AutoTeardown = "8h"
  }
}
```

### Part 3: Write Terraform Tests (40 points)

Create `tests/s3_bucket.tftest.hcl` with the following tests:

#### Test 1: Bucket Creates with Correct Name (10 points)

```hcl
run "bucket_has_correct_name" {
  command = plan

  assert {
    condition     = # Your condition here
    error_message = "Bucket name should contain the expected prefix"
  }
}
```

#### Test 2: Versioning is Enabled (10 points)

```hcl
run "versioning_is_enabled" {
  command = plan

  assert {
    condition     = # Your condition here
    error_message = "Versioning should be enabled by default"
  }
}
```

#### Test 3: Encryption is Configured (10 points)

```hcl
run "encryption_is_configured" {
  command = plan

  assert {
    condition     = # Your condition here
    error_message = "Server-side encryption should be AES256"
  }
}
```

#### Test 4: Required Tags are Present (10 points)

```hcl
run "required_tags_present" {
  command = plan

  assert {
    condition     = # Your condition here
    error_message = "Required tags should be present"
  }
}
```

## Running Tests

```bash
# Initialize Terraform
terraform init

# Run all tests
terraform test

# Run tests with verbose output
terraform test -verbose

# Run a specific test file
terraform test -filter=tests/s3_bucket.tftest.hcl
```

### Expected Output

```
tests/s3_bucket.tftest.hcl... in progress
  run "bucket_has_correct_name"... pass
  run "versioning_is_enabled"... pass
  run "encryption_is_configured"... pass
  run "required_tags_present"... pass
tests/s3_bucket.tftest.hcl... tearing down
tests/s3_bucket.tftest.hcl... pass

Success! 4 passed, 0 failed.
```

## Hints

### Module Variable Definition

```hcl
# modules/s3-bucket/variables.tf
variable "bucket_name" {
  description = "Base name for the S3 bucket"
  type        = string

  validation {
    condition     = length(var.bucket_name) >= 3
    error_message = "Bucket name must be at least 3 characters"
  }
}

variable "enable_versioning" {
  description = "Enable versioning on the bucket"
  type        = bool
  default     = true
}
```

### Merging Tags

```hcl
locals {
  default_tags = {
    Name        = var.bucket_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "s3-bucket"
  }

  all_tags = merge(local.default_tags, var.tags)
}

resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  tags   = local.all_tags
}
```

### Test Assertions

```hcl
# Check a string contains something
condition = can(regex("expected", module.lab_bucket.bucket_id))

# Check a boolean
condition = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Enabled"

# Check a map contains a key
condition = contains(keys(aws_s3_bucket.this.tags), "Environment")
```

## Submission

1. Ensure all tests pass: `terraform test`
2. Commit your code to your fork
3. Create a Pull Request with title: `Week 01 Lab 00 - [Your Name]`
4. Wait for the grading workflow to run

## Grading Criteria

| Category | Points | Criteria |
|----------|--------|----------|
| Code Quality | 25 | Formatting, validation, no hardcoded values |
| Module Structure | 20 | Proper variables, outputs, resource organization |
| Module Functionality | 20 | Creates S3 with versioning, encryption, tags |
| Test Coverage | 25 | All 4 required tests pass |
| Documentation | 10 | Comments explaining module usage |
| **Total** | **100** | |

## Resources

- [Terraform Modules Documentation](https://developer.hashicorp.com/terraform/language/modules)
- [Terraform Test Documentation](https://developer.hashicorp.com/terraform/language/tests)
- [Module Best Practices](https://developer.hashicorp.com/terraform/language/modules/develop)

## Estimated Time

2-3 hours

## Next Steps

In Lab 01, you'll use this S3 module to create a static website bucket and deploy a Hugo blog with CloudFront CDN!
