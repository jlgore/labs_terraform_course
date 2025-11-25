# Terraform version and provider requirements
terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# AWS Provider configuration
provider "aws" {
  region = "us-east-1"
}

# Data source to get the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-kernel-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Import SSH public key to AWS
resource "aws_key_pair" "wordpress" {
  key_name   = "wordpress-${var.student_name}"
  public_key = file("~/.ssh/wordpress-lab.pub")

  tags = {
    Name         = "WordPress SSH Key - ${var.student_name}"
    Environment  = "Learning"
    ManagedBy    = "Terraform"
    Student      = var.student_name
    AutoTeardown = "8h"
  }
}

# Security group for WordPress server
resource "aws_security_group" "wordpress" {
  name        = "wordpress-${var.student_name}"
  description = "Security group for WordPress server"

  # SSH access from your IP only
  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # HTTP access from anywhere (for WordPress)
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access from anywhere (for future SSL)
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # CRITICAL: Terraform does NOT add default egress rules!
  # Without this, your instance cannot reach the internet
  # to download packages, WordPress, or anything else.
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name         = "wordpress-sg-${var.student_name}"
    Environment  = "Learning"
    ManagedBy    = "Terraform"
    Student      = var.student_name
    AutoTeardown = "8h"
  }
}

# EC2 instance running WordPress
resource "aws_instance" "wordpress" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.wordpress.key_name
  vpc_security_group_ids = [aws_security_group.wordpress.id]

  # User data script to install WordPress
  user_data = file("${path.module}/user_data.sh")

  # IMDSv2 configuration (enhanced security)
  metadata_options {
    http_endpoint               = "enabled"  # Enable IMDS
    http_tokens                 = "required" # Require IMDSv2 (session tokens)
    http_put_response_hop_limit = 1          # Restrict to instance only
    instance_metadata_tags      = "enabled"  # Allow access to instance tags
  }

  # Root volume configuration
  root_block_device {
    volume_size = 30 # GB - enough for WordPress and database
    volume_type = "gp2"
    encrypted   = true
  }

  tags = {
    Name         = "wordpress-${var.student_name}"
    Environment  = "Learning"
    ManagedBy    = "Terraform"
    Student      = var.student_name
    AutoTeardown = "8h"
  }
}


