#!/bin/bash
#
# Lab 01 Grading Script
# Complete grading for EC2 Instance with IMDSv2 lab
#
# Usage: grade.sh <student-work-dir>
# Output: JSON grading results to stdout
#
# Grading Categories:
#   - Code Quality (25 points)
#   - Functionality (30 points)
#   - Cost Management (20 points)
#   - Security (15 points)
#   - Documentation (10 points)
#

set -e

WORK_DIR="${1:-.}"
PLAN_FILE="${2:-/tmp/plan.json}"
INFRACOST_FILE="${3:-/tmp/infracost.json}"
CHECKOV_FILE="${4:-/tmp/checkov.json}"

# Initialize scores
CODE_QUALITY=0
CODE_QUALITY_MAX=25
FUNCTIONALITY=0
FUNCTIONALITY_MAX=30
COST_MGMT=0
COST_MGMT_MAX=20
SECURITY=0
SECURITY_MAX=15
DOCUMENTATION=0
DOCUMENTATION_MAX=10

# Initialize check results arrays
declare -a CODE_QUALITY_CHECKS=()
declare -a FUNCTIONALITY_CHECKS=()
declare -a COST_MGMT_CHECKS=()
declare -a SECURITY_CHECKS=()
declare -a DOCUMENTATION_CHECKS=()
declare -a ERRORS=()
declare -a WARNINGS=()

# Helper to add check result
add_check() {
    local category=$1
    local name=$2
    local points=$3
    local max_points=$4
    local status=$5
    local message=$6

    local check="{\"name\":\"$name\",\"points\":$points,\"max_points\":$max_points,\"status\":\"$status\",\"message\":\"$message\"}"

    case $category in
        "code_quality") CODE_QUALITY_CHECKS+=("$check") ;;
        "functionality") FUNCTIONALITY_CHECKS+=("$check") ;;
        "cost_mgmt") COST_MGMT_CHECKS+=("$check") ;;
        "security") SECURITY_CHECKS+=("$check") ;;
        "documentation") DOCUMENTATION_CHECKS+=("$check") ;;
    esac
}

echo "================================================" >&2
echo "Lab 01 Grading - EC2 with IMDSv2" >&2
echo "================================================" >&2
echo "" >&2

cd "$WORK_DIR"

# ==================== CODE QUALITY (25 points) ====================
echo "📋 Checking Code Quality..." >&2

# Check 1: Terraform formatting (5 points)
if terraform fmt -check -recursive . >/dev/null 2>&1; then
    CODE_QUALITY=$((CODE_QUALITY + 5))
    add_check "code_quality" "Terraform Formatting" 5 5 "pass" "Code is properly formatted"
    echo "  ✅ Terraform formatting: PASS" >&2
else
    add_check "code_quality" "Terraform Formatting" 0 5 "fail" "Run 'terraform fmt' to fix formatting"
    echo "  ❌ Terraform formatting: FAIL" >&2
fi

# Check 2: Terraform validation (5 points)
if terraform validate >/dev/null 2>&1; then
    CODE_QUALITY=$((CODE_QUALITY + 5))
    add_check "code_quality" "Terraform Validation" 5 5 "pass" "Configuration is valid"
    echo "  ✅ Terraform validation: PASS" >&2
else
    add_check "code_quality" "Terraform Validation" 0 5 "fail" "Configuration has errors"
    ERRORS+=("Terraform validation failed")
    echo "  ❌ Terraform validation: FAIL" >&2
fi

# Check 3: No hardcoded credentials (5 points)
CRED_ISSUES=0
if grep -r "aws_access_key_id\s*=\s*\"[A-Z0-9]" . 2>/dev/null; then
    CRED_ISSUES=$((CRED_ISSUES + 1))
fi
if grep -r "aws_secret_access_key\s*=\s*\"" . 2>/dev/null; then
    CRED_ISSUES=$((CRED_ISSUES + 1))
fi

if [ $CRED_ISSUES -eq 0 ]; then
    CODE_QUALITY=$((CODE_QUALITY + 5))
    add_check "code_quality" "No Hardcoded Credentials" 5 5 "pass" "No credentials found in code"
    echo "  ✅ No hardcoded credentials: PASS" >&2
else
    add_check "code_quality" "No Hardcoded Credentials" 0 5 "fail" "Found $CRED_ISSUES credential issues"
    ERRORS+=("Hardcoded credentials detected")
    echo "  ❌ No hardcoded credentials: FAIL" >&2
fi

# Check 4: main.tf exists (5 points)
if [ -f "main.tf" ]; then
    CODE_QUALITY=$((CODE_QUALITY + 5))
    add_check "code_quality" "File Structure" 5 5 "pass" "main.tf exists"
    echo "  ✅ File structure: PASS" >&2
else
    add_check "code_quality" "File Structure" 0 5 "fail" "main.tf not found"
    ERRORS+=("main.tf not found")
    echo "  ❌ File structure: FAIL" >&2
fi

# Check 5: Terraform version requirement (5 points)
if grep -qE 'required_version.*[">]=.*(1\.(9|[1-9][0-9])|[2-9]\.)' *.tf 2>/dev/null; then
    CODE_QUALITY=$((CODE_QUALITY + 5))
    add_check "code_quality" "Terraform Version" 5 5 "pass" "Version >= 1.9.0 required"
    echo "  ✅ Terraform version requirement: PASS" >&2
else
    add_check "code_quality" "Terraform Version" 0 5 "fail" "Missing required_version >= 1.9.0"
    WARNINGS+=("Missing Terraform version requirement")
    echo "  ❌ Terraform version requirement: FAIL" >&2
fi

echo "" >&2

# ==================== FUNCTIONALITY (30 points) ====================
echo "📋 Checking Functionality..." >&2

if [ -f "$PLAN_FILE" ]; then
    # Check 1: AWS Key Pair (4 points)
    KEY_PAIR_COUNT=$(jq "[.planned_values.root_module.resources[]? | select(.type == \"aws_key_pair\")] | length" "$PLAN_FILE")
    if [ "$KEY_PAIR_COUNT" -gt 0 ]; then
        KEY_POINTS=2
        KEY_NAME=$(jq -r '[.planned_values.root_module.resources[]? | select(.type == "aws_key_pair") | .values.key_name] | first' "$PLAN_FILE")
        PUBLIC_KEY=$(jq -r '[.planned_values.root_module.resources[]? | select(.type == "aws_key_pair") | .values.public_key] | first' "$PLAN_FILE")

        if [ "$KEY_NAME" != "null" ] && [ -n "$KEY_NAME" ]; then
            KEY_POINTS=$((KEY_POINTS + 1))
        fi
        if [ "$PUBLIC_KEY" != "null" ] && [ -n "$PUBLIC_KEY" ]; then
            KEY_POINTS=$((KEY_POINTS + 1))
        fi

        FUNCTIONALITY=$((FUNCTIONALITY + KEY_POINTS))
        add_check "functionality" "AWS Key Pair" $KEY_POINTS 4 "pass" "Key pair configured"
        echo "  ✅ AWS Key Pair: $KEY_POINTS/4 points" >&2
    else
        add_check "functionality" "AWS Key Pair" 0 4 "fail" "aws_key_pair resource not found"
        ERRORS+=("Key pair not configured")
        echo "  ❌ AWS Key Pair: NOT FOUND" >&2
    fi

    # Check 2: Security Group with SSH restriction (6 points)
    SG_COUNT=$(jq "[.planned_values.root_module.resources[]? | select(.type == \"aws_security_group\")] | length" "$PLAN_FILE")
    if [ "$SG_COUNT" -gt 0 ]; then
        SG_POINTS=2

        # Check SSH ingress
        SSH_RULE=$(jq -r '[.planned_values.root_module.resources[]? | select(.type == "aws_security_group") | .values.ingress[]? | select(.from_port == 22)] | first | .from_port' "$PLAN_FILE")
        if [ "$SSH_RULE" == "22" ]; then
            SG_POINTS=$((SG_POINTS + 2))

            # CRITICAL: Check SSH is NOT from 0.0.0.0/0
            SSH_CIDR=$(jq -r '[.planned_values.root_module.resources[]? | select(.type == "aws_security_group") | .values.ingress[]? | select(.from_port == 22) | .cidr_blocks[]?] | first' "$PLAN_FILE")
            if [ "$SSH_CIDR" != "0.0.0.0/0" ] && [ "$SSH_CIDR" != "null" ] && [ -n "$SSH_CIDR" ]; then
                SG_POINTS=$((SG_POINTS + 2))
                echo "  ✅ SSH restricted to: $SSH_CIDR" >&2
            else
                ERRORS+=("SSH open to 0.0.0.0/0 - security risk!")
                echo "  ❌ SSH open to 0.0.0.0/0 - SECURITY RISK!" >&2
            fi
        fi

        FUNCTIONALITY=$((FUNCTIONALITY + SG_POINTS))
        add_check "functionality" "Security Group" $SG_POINTS 6 "$([ $SG_POINTS -ge 4 ] && echo 'pass' || echo 'partial')" "Security group with SSH rules"
        echo "  ✅ Security Group: $SG_POINTS/6 points" >&2
    else
        add_check "functionality" "Security Group" 0 6 "fail" "aws_security_group resource not found"
        ERRORS+=("Security group not configured")
        echo "  ❌ Security Group: NOT FOUND" >&2
    fi

    # Check 3: EC2 Instance (5 points)
    EC2_COUNT=$(jq "[.planned_values.root_module.resources[]? | select(.type == \"aws_instance\")] | length" "$PLAN_FILE")
    if [ "$EC2_COUNT" -gt 0 ]; then
        EC2_POINTS=2

        INSTANCE_TYPE=$(jq -r '[.planned_values.root_module.resources[]? | select(.type == "aws_instance") | .values.instance_type] | first' "$PLAN_FILE")
        if [[ "$INSTANCE_TYPE" =~ ^t[2-4] ]]; then
            EC2_POINTS=$((EC2_POINTS + 1))
        fi

        KEY_REF=$(jq -r '[.planned_values.root_module.resources[]? | select(.type == "aws_instance") | .values.key_name] | first' "$PLAN_FILE")
        if [ "$KEY_REF" != "null" ] && [ -n "$KEY_REF" ]; then
            EC2_POINTS=$((EC2_POINTS + 1))
        fi

        SG_ATTACHED=$(jq '[.planned_values.root_module.resources[]? | select(.type == "aws_instance") | .values.vpc_security_group_ids[]?] | length' "$PLAN_FILE")
        if [ "$SG_ATTACHED" -gt 0 ]; then
            EC2_POINTS=$((EC2_POINTS + 1))
        fi

        FUNCTIONALITY=$((FUNCTIONALITY + EC2_POINTS))
        add_check "functionality" "EC2 Instance" $EC2_POINTS 5 "pass" "Instance type: $INSTANCE_TYPE"
        echo "  ✅ EC2 Instance: $EC2_POINTS/5 points" >&2
    else
        add_check "functionality" "EC2 Instance" 0 5 "fail" "aws_instance resource not found"
        ERRORS+=("EC2 instance not configured")
        echo "  ❌ EC2 Instance: NOT FOUND" >&2
    fi

    # Check 4: IMDSv2 Configuration (10 points) - CRITICAL
    echo "  Checking IMDSv2 configuration..." >&2
    METADATA_OPTIONS=$(jq '[.planned_values.root_module.resources[]? | select(.type == "aws_instance") | .values.metadata_options[]?] | length' "$PLAN_FILE")

    if [ "$METADATA_OPTIONS" -gt 0 ]; then
        IMDS_POINTS=2

        HTTP_TOKENS=$(jq -r '[.planned_values.root_module.resources[]? | select(.type == "aws_instance") | .values.metadata_options[0].http_tokens] | first' "$PLAN_FILE")
        if [ "$HTTP_TOKENS" == "required" ]; then
            IMDS_POINTS=$((IMDS_POINTS + 4))
            echo "    ✅ http_tokens = required (IMDSv2 enforced)" >&2
        else
            ERRORS+=("IMDSv2 not enforced - http_tokens must be 'required'")
            echo "    ❌ http_tokens = $HTTP_TOKENS (must be 'required')" >&2
        fi

        HTTP_ENDPOINT=$(jq -r '[.planned_values.root_module.resources[]? | select(.type == "aws_instance") | .values.metadata_options[0].http_endpoint] | first' "$PLAN_FILE")
        if [ "$HTTP_ENDPOINT" == "enabled" ]; then
            IMDS_POINTS=$((IMDS_POINTS + 2))
            echo "    ✅ http_endpoint = enabled" >&2
        fi

        HOP_LIMIT=$(jq -r '[.planned_values.root_module.resources[]? | select(.type == "aws_instance") | .values.metadata_options[0].http_put_response_hop_limit] | first' "$PLAN_FILE")
        if [ "$HOP_LIMIT" == "1" ]; then
            IMDS_POINTS=$((IMDS_POINTS + 2))
            echo "    ✅ http_put_response_hop_limit = 1" >&2
        fi

        FUNCTIONALITY=$((FUNCTIONALITY + IMDS_POINTS))
        add_check "functionality" "IMDSv2 Configuration" $IMDS_POINTS 10 "$([ $IMDS_POINTS -ge 6 ] && echo 'pass' || echo 'partial')" "IMDSv2 security settings"
        echo "  ✅ IMDSv2: $IMDS_POINTS/10 points" >&2
    else
        add_check "functionality" "IMDSv2 Configuration" 0 10 "fail" "metadata_options block not found - IMDSv2 not configured!"
        ERRORS+=("IMDSv2 not configured - critical security requirement")
        echo "  ❌ IMDSv2: NOT CONFIGURED" >&2
    fi

    # Check 5: Data Source for AMI (3 points)
    DATA_AMI=$(jq -r '.configuration.root_module.data[]? | select(.type == "aws_ami") | .type' "$PLAN_FILE")
    if [ "$DATA_AMI" == "aws_ami" ]; then
        AMI_POINTS=2
        MOST_RECENT=$(jq -r '[.configuration.root_module.data[]? | select(.type == "aws_ami") | .expressions.most_recent.constant_value] | first' "$PLAN_FILE")
        if [ "$MOST_RECENT" == "true" ]; then
            AMI_POINTS=$((AMI_POINTS + 1))
        fi
        FUNCTIONALITY=$((FUNCTIONALITY + AMI_POINTS))
        add_check "functionality" "AMI Data Source" $AMI_POINTS 3 "pass" "Dynamic AMI lookup configured"
        echo "  ✅ AMI Data Source: $AMI_POINTS/3 points" >&2
    else
        add_check "functionality" "AMI Data Source" 0 3 "fail" "aws_ami data source not found"
        WARNINGS+=("Using hardcoded AMI instead of data source")
        echo "  ❌ AMI Data Source: NOT FOUND" >&2
    fi

    # Check 6: Outputs defined (2 points)
    if [ -f "outputs.tf" ] && [ -s "outputs.tf" ]; then
        OUTPUT_COUNT=$(grep -c "^output " outputs.tf 2>/dev/null || echo 0)
        if [ "$OUTPUT_COUNT" -gt 0 ]; then
            FUNCTIONALITY=$((FUNCTIONALITY + 2))
            add_check "functionality" "Outputs Defined" 2 2 "pass" "$OUTPUT_COUNT outputs defined"
            echo "  ✅ Outputs: $OUTPUT_COUNT defined" >&2
        else
            add_check "functionality" "Outputs Defined" 0 2 "fail" "No outputs defined"
            echo "  ❌ Outputs: NONE" >&2
        fi
    else
        add_check "functionality" "Outputs Defined" 0 2 "fail" "outputs.tf not found"
        echo "  ❌ Outputs: NOT FOUND" >&2
    fi
else
    add_check "functionality" "Terraform Plan" 0 30 "fail" "Plan file not found"
    ERRORS+=("Terraform plan failed")
    echo "  ❌ Plan file not found" >&2
fi

echo "" >&2

# ==================== COST MANAGEMENT (20 points) ====================
echo "📋 Checking Cost Management..." >&2

# Check 1: Infracost analysis (5 points)
if [ -f "$INFRACOST_FILE" ]; then
    COST_MGMT=$((COST_MGMT + 5))
    add_check "cost_mgmt" "Infracost Analysis" 5 5 "pass" "Cost analysis completed"
    echo "  ✅ Infracost analysis: PASS" >&2

    # Check 2: Within budget (10 points)
    MONTHLY_COST=$(jq -r '.totalMonthlyCost // "0"' "$INFRACOST_FILE")
    COST_LIMIT=10.00

    if awk "BEGIN {exit !($MONTHLY_COST <= $COST_LIMIT)}"; then
        COST_MGMT=$((COST_MGMT + 10))
        add_check "cost_mgmt" "Within Budget" 10 10 "pass" "Estimated cost: \$$MONTHLY_COST/month (limit: \$$COST_LIMIT)"
        echo "  ✅ Within budget: \$$MONTHLY_COST/month" >&2
    else
        add_check "cost_mgmt" "Within Budget" 0 10 "fail" "Cost \$$MONTHLY_COST exceeds \$$COST_LIMIT/month"
        WARNINGS+=("Cost exceeds budget")
        echo "  ❌ Over budget: \$$MONTHLY_COST/month" >&2
    fi
else
    add_check "cost_mgmt" "Infracost Analysis" 0 5 "fail" "Infracost analysis not available"
    add_check "cost_mgmt" "Within Budget" 0 10 "skip" "Cannot check without Infracost"
    echo "  ⚠️  Infracost not available" >&2
fi

# Check 3: AutoTeardown tag (5 points)
if [ -f "$PLAN_FILE" ]; then
    HAS_TEARDOWN=$(jq -r '[.planned_values.root_module.resources[]? | select(.values.tags.AutoTeardown != null)] | length' "$PLAN_FILE")
    if [ "$HAS_TEARDOWN" -gt 0 ]; then
        COST_MGMT=$((COST_MGMT + 5))
        add_check "cost_mgmt" "AutoTeardown Tag" 5 5 "pass" "AutoTeardown tag found on $HAS_TEARDOWN resource(s)"
        echo "  ✅ AutoTeardown tag: FOUND" >&2
    else
        add_check "cost_mgmt" "AutoTeardown Tag" 0 5 "fail" "AutoTeardown tag missing from resources"
        WARNINGS+=("AutoTeardown tag missing")
        echo "  ❌ AutoTeardown tag: NOT FOUND" >&2
    fi
fi

echo "" >&2

# ==================== SECURITY (15 points) ====================
echo "📋 Checking Security..." >&2

if [ -f "$CHECKOV_FILE" ]; then
    FAILED_CHECKS=$(jq '.results.failed_checks | length // 0' "$CHECKOV_FILE" 2>/dev/null || echo "0")
    PASSED_CHECKS=$(jq '.results.passed_checks | length // 0' "$CHECKOV_FILE" 2>/dev/null || echo "0")

    echo "  Checkov: $PASSED_CHECKS passed, $FAILED_CHECKS failed" >&2

    if [ "$FAILED_CHECKS" -eq 0 ]; then
        SECURITY=$((SECURITY + 15))
        add_check "security" "Checkov Security Scan" 15 15 "pass" "No security issues found"
        echo "  ✅ Security scan: PASS (15/15)" >&2
    elif [ "$FAILED_CHECKS" -le 3 ]; then
        SECURITY=$((SECURITY + 10))
        add_check "security" "Checkov Security Scan" 10 15 "partial" "$FAILED_CHECKS minor security issues"
        echo "  ⚠️  Security scan: PARTIAL (10/15)" >&2
    elif [ "$FAILED_CHECKS" -le 5 ]; then
        SECURITY=$((SECURITY + 5))
        add_check "security" "Checkov Security Scan" 5 15 "partial" "$FAILED_CHECKS security issues"
        echo "  ⚠️  Security scan: PARTIAL (5/15)" >&2
    else
        add_check "security" "Checkov Security Scan" 0 15 "fail" "$FAILED_CHECKS security issues found"
        ERRORS+=("Multiple security issues detected")
        echo "  ❌ Security scan: FAIL (0/15)" >&2
    fi
else
    add_check "security" "Checkov Security Scan" 0 15 "skip" "Security scan not available"
    echo "  ⚠️  Checkov not available" >&2
fi

echo "" >&2

# ==================== DOCUMENTATION (10 points) ====================
echo "📋 Checking Documentation..." >&2

# Check 1: Code comments (5 points)
COMMENT_LINES=$(grep -r "^\s*#" *.tf 2>/dev/null | wc -l || echo 0)
if [ "$COMMENT_LINES" -ge 5 ]; then
    DOCUMENTATION=$((DOCUMENTATION + 5))
    add_check "documentation" "Code Comments" 5 5 "pass" "$COMMENT_LINES comment lines found"
    echo "  ✅ Code comments: $COMMENT_LINES lines" >&2
elif [ "$COMMENT_LINES" -ge 2 ]; then
    DOCUMENTATION=$((DOCUMENTATION + 3))
    add_check "documentation" "Code Comments" 3 5 "partial" "$COMMENT_LINES comment lines (need 5+)"
    echo "  ⚠️  Code comments: $COMMENT_LINES lines (need more)" >&2
else
    add_check "documentation" "Code Comments" 0 5 "fail" "Insufficient comments"
    echo "  ❌ Code comments: NOT ENOUGH" >&2
fi

# Check 2: README exists (5 points)
if [ -f "README.md" ] && [ -s "README.md" ]; then
    DOCUMENTATION=$((DOCUMENTATION + 5))
    add_check "documentation" "README" 5 5 "pass" "README.md exists"
    echo "  ✅ README.md: FOUND" >&2
else
    add_check "documentation" "README" 0 5 "fail" "README.md not found or empty"
    echo "  ❌ README.md: NOT FOUND" >&2
fi

echo "" >&2

# ==================== CALCULATE FINAL GRADE ====================
TOTAL=$((CODE_QUALITY + FUNCTIONALITY + COST_MGMT + SECURITY + DOCUMENTATION))
TOTAL_MAX=$((CODE_QUALITY_MAX + FUNCTIONALITY_MAX + COST_MGMT_MAX + SECURITY_MAX + DOCUMENTATION_MAX))

if [ $TOTAL -ge 90 ]; then
    LETTER="A"
elif [ $TOTAL -ge 80 ]; then
    LETTER="B"
elif [ $TOTAL -ge 70 ]; then
    LETTER="C"
elif [ $TOTAL -ge 60 ]; then
    LETTER="D"
else
    LETTER="F"
fi

echo "================================================" >&2
echo "Final Grade: $TOTAL/$TOTAL_MAX ($LETTER)" >&2
echo "================================================" >&2

# ==================== OUTPUT JSON ====================

# Helper to join array elements
join_array() {
    local IFS=','
    echo "$*"
}

cat <<EOF
{
  "lab": {
    "week": 0,
    "lab": 1,
    "name": "EC2 Instance with IMDSv2"
  },
  "scores": {
    "code_quality": {"earned": $CODE_QUALITY, "max": $CODE_QUALITY_MAX},
    "functionality": {"earned": $FUNCTIONALITY, "max": $FUNCTIONALITY_MAX},
    "cost_management": {"earned": $COST_MGMT, "max": $COST_MGMT_MAX},
    "security": {"earned": $SECURITY, "max": $SECURITY_MAX},
    "documentation": {"earned": $DOCUMENTATION, "max": $DOCUMENTATION_MAX}
  },
  "total": {"earned": $TOTAL, "max": $TOTAL_MAX},
  "letter_grade": "$LETTER",
  "checks": {
    "code_quality": [$(join_array "${CODE_QUALITY_CHECKS[@]}")],
    "functionality": [$(join_array "${FUNCTIONALITY_CHECKS[@]}")],
    "cost_management": [$(join_array "${COST_MGMT_CHECKS[@]}")],
    "security": [$(join_array "${SECURITY_CHECKS[@]}")],
    "documentation": [$(join_array "${DOCUMENTATION_CHECKS[@]}")]
  },
  "errors": [$(printf '"%s",' "${ERRORS[@]}" | sed 's/,$//')]$( [ ${#ERRORS[@]} -eq 0 ] && echo "" ),
  "warnings": [$(printf '"%s",' "${WARNINGS[@]}" | sed 's/,$//')]$( [ ${#WARNINGS[@]} -eq 0 ] && echo "" )
}
EOF
