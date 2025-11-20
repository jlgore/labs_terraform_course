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

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Import SSH public key to AWS
resource "aws_key_pair" "lab_key" {
  key_name   = "terraform-lab-01-${var.student_name}"
  public_key = file("~/.ssh/terraform-lab-01.pub")

  tags = {
    Name         = "Lab 01 SSH Key"
    Environment  = "Learning"
    ManagedBy    = "Terraform"
    Student      = var.student_name
    AutoTeardown = "8h"
  }
}
# Security group for EC2 instance
resource "aws_security_group" "lab_sg" {
  name        = "terraform-lab-01-${var.student_name}"
  description = "Security group for Lab 01 EC2 instance"

  # SSH access from your IP only
  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name         = "Lab 01 Security Group"
    Environment  = "Learning"
    ManagedBy    = "Terraform"
    Student      = var.student_name
    AutoTeardown = "8h"
  }
}

# EC2 instance with IMDSv2 required
resource "aws_instance" "lab_instance" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.lab_key.key_name

  vpc_security_group_ids = [aws_security_group.lab_sg.id]

  # IMDSv2 configuration (enhanced security)
  metadata_options {
    http_endpoint               = "enabled"  # Enable IMDS
    http_tokens                 = "required" # Require IMDSv2 (session tokens)
    http_put_response_hop_limit = 1          # Restrict to instance only
    instance_metadata_tags      = "enabled"  # Allow access to instance tags
  }

  # User data script to install and configure basic tools
  user_data = <<-EOF
              #!/bin/bash
              # Update system
              yum update -y
              
              # Install useful tools
              yum install -y htop tree
              
              # Create a welcome message
              echo "Welcome to Lab 01 EC2 Instance" > /home/ec2-user/welcome.txt
              echo "This instance was created with Terraform" >> /home/ec2-user/welcome.txt
              chown ec2-user:ec2-user /home/ec2-user/welcome.txt
              EOF

  tags = {
    Name         = "Lab 01 EC2 Instance - ${var.student_name}"
    Environment  = "Learning"
    ManagedBy    = "Terraform"
    Student      = var.student_name
    AutoTeardown = "8h"
  }
}




