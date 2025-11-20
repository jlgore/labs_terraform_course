#!/bin/bash
#
# Lab 01 Setup Script
# Prepares the environment for Terraform validation
#

set -e

echo "🔧 Setting up Lab 01 environment..."

# Create SSH key pair for validation (mimics student's local setup)
mkdir -p ~/.ssh
if [ ! -f ~/.ssh/terraform-lab-01 ]; then
  echo "📝 Generating SSH key pair..."
  ssh-keygen -t rsa -b 4096 -f ~/.ssh/terraform-lab-01 -N "" -q
  echo "✅ SSH key pair created"
else
  echo "✅ SSH key pair already exists"
fi

echo "✅ Lab 01 setup complete"
