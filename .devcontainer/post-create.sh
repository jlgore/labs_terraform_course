#!/bin/bash
#
# Post-create script for Terraform Course Codespace
# This runs automatically when the Codespace is created
#

set -e

echo "🚀 Setting up Terraform Course environment..."

# Create Terraform plugin cache directory
# Use sudo if needed (handles permission issues in some container setups)
if ! mkdir -p ~/.terraform.d/plugin-cache 2>/dev/null; then
  echo "⚠️  Creating terraform directory with sudo..."
  sudo mkdir -p ~/.terraform.d/plugin-cache
  sudo chown -R $(whoami):$(whoami) ~/.terraform.d
fi

# Install vim and neovim
echo "📝 Installing vim and neovim..."
sudo apt-get update -qq && sudo apt-get install -y -qq vim neovim

# Install Infracost
echo "📊 Installing Infracost..."
curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh

# Install checkov for security scanning
echo "🔒 Installing Checkov..."
pip3 install --quiet checkov

# Install tflint
echo "🔍 Installing TFLint..."
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Verify installations
echo ""
echo "✅ Environment setup complete!"
echo ""
echo "Installed tools:"
echo "  - Terraform: $(terraform version -json | jq -r '.terraform_version')"
echo "  - Hugo:      $(hugo version | grep -oP 'v[\d.]+')"
echo "  - AWS CLI:   $(aws --version | cut -d' ' -f1)"
echo "  - Infracost: $(infracost --version)"
echo "  - Checkov:   $(checkov --version 2>/dev/null | head -1)"
echo "  - TFLint:    $(tflint --version | head -1)"
echo "  - gh CLI:    $(gh --version | head -1)"
echo "  - vim:       $(vim --version | head -1 | cut -d' ' -f5)"
echo "  - neovim:    $(nvim --version | head -1)"
echo ""
echo "📚 Ready for Terraform labs!"
echo ""
echo "Quick start:"
echo "  1. Configure AWS: aws configure"
echo "  2. Or use GitHub Secrets for CI/CD"
echo ""
