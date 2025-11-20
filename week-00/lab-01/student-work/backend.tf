terraform {
  backend "s3" {
    bucket       = "terraform-state-197005419426"
    key          = "week-00/lab-01/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
