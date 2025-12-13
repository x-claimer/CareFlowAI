#!/bin/bash

###############################################################################
# CareFlowAI Infrastructure Deployment Script
# This script deploys the complete AWS infrastructure using CloudFormation
###############################################################################

set -e  # Exit on error

# Determine PROJECT_ROOT
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Convert to Windows path if on Git Bash/MINGW
if [[ "$(uname -s)" == MINGW* ]] || [[ "$(uname -s)" == MSYS* ]]; then
    # Convert /e/path to E:/path format for AWS CLI
    PROJECT_ROOT=$(echo "$PROJECT_ROOT" | sed 's|^/\([a-z]\)/|\U\1:/|')
fi

# Load environment variables from .env file
if [ -f "$PROJECT_ROOT/aws/.env" ]; then
    export $(grep -v '^#' "$PROJECT_ROOT/aws/.env" | grep -v '^$' | xargs)
    echo "Loaded configuration from $PROJECT_ROOT/aws/.env"
else
    echo "Warning: .env file not found at $PROJECT_ROOT/aws/.env"
    echo "Using default values or environment variables"
fi

# Configuration with defaults from .env or hardcoded fallbacks
STACK_NAME_PREFIX="${STACK_NAME_PREFIX:-CareFlowAI}"
REGION="${REGION:-us-east-1}"
KEY_NAME="${KEY_NAME:-CareFlowAI-Key-New}"
INSTANCE_TYPE="${INSTANCE_TYPE:-t2.micro}"
DEPLOY_API_GATEWAY="${DEPLOY_API_GATEWAY:-yes}"
AWS_CLI="${AWS_CLI:-}"  # Will be auto-detected if not set

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    COLOR=$1
    MESSAGE=$2
    echo -e "${COLOR}${MESSAGE}${NC}"
}

# Function to check if stack exists
stack_exists() {
    "$AWS_CLI" cloudformation describe-stacks \
        --stack-name $1 \
        --region $REGION \
        &> /dev/null
}

# Function to wait for stack creation
wait_for_stack() {
    STACK_NAME=$1
    print_message "$YELLOW" "Waiting for stack $STACK_NAME to complete..."

    "$AWS_CLI" cloudformation wait stack-create-complete \
        --stack-name $STACK_NAME \
        --region $REGION

    if [ $? -eq 0 ]; then
        print_message "$GREEN" "Stack $STACK_NAME created successfully!"
    else
        print_message "$RED" "Stack $STACK_NAME creation failed!"
        exit 1
    fi
}

# Function to wait for stack update
wait_for_stack_update() {
    STACK_NAME=$1
    print_message "$YELLOW" "Waiting for stack $STACK_NAME update to complete..."

    "$AWS_CLI" cloudformation wait stack-update-complete \
        --stack-name $STACK_NAME \
        --region $REGION

    if [ $? -eq 0 ]; then
        print_message "$GREEN" "Stack $STACK_NAME updated successfully!"
    else
        print_message "$RED" "Stack $STACK_NAME update failed!"
        exit 1
    fi
}

# Function to get stack status
get_stack_status() {
    "$AWS_CLI" cloudformation describe-stacks \
        --stack-name $1 \
        --region $REGION \
        --query 'Stacks[0].StackStatus' \
        --output text 2>/dev/null
}

# Function to update or create stack
update_or_create_stack() {
    STACK_NAME=$1
    TEMPLATE_FILE=$2
    shift 2
    EXTRA_PARAMS=("$@")

    if stack_exists $STACK_NAME; then
        STACK_STATUS=$(get_stack_status $STACK_NAME)
        print_message "$YELLOW" "Stack $STACK_NAME already exists with status: $STACK_STATUS"

        if [ "$STACK_STATUS" = "CREATE_COMPLETE" ] || [ "$STACK_STATUS" = "UPDATE_COMPLETE" ]; then
            print_message "$GREEN" "✓ Using existing stack $STACK_NAME"
            return 0
        else
            print_message "$RED" "Stack $STACK_NAME is in $STACK_STATUS state. Please check and fix manually."
            exit 1
        fi
    else
        print_message "$YELLOW" "Creating stack $STACK_NAME..."
        "$AWS_CLI" cloudformation create-stack \
            --stack-name $STACK_NAME \
            --template-body file://"$TEMPLATE_FILE" \
            "${EXTRA_PARAMS[@]}" \
            --region $REGION

        wait_for_stack $STACK_NAME
    fi
}

# Resolve AWS CLI path
if [ -z "$AWS_CLI" ]; then
    # Check if we're on Git Bash/MINGW (Windows)
    if [[ "$(uname -s)" == MINGW* ]] || [[ "$(uname -s)" == MSYS* ]]; then
        # On Git Bash/Windows, try to find AWS CLI
        # First check if aws.exe is in PATH (most reliable)
        if command -v aws.exe >/dev/null 2>&1; then
            AWS_CLI="aws.exe"
        elif command -v aws >/dev/null 2>&1; then
            AWS_CLI="aws"
        # Then check standard Windows installation paths
        elif [ -f "/c/Program Files/Amazon/AWSCLIV2/aws.exe" ]; then
            AWS_CLI="/c/Program Files/Amazon/AWSCLIV2/aws.exe"
        elif [ -f "/c/Program Files/Amazon/AWSCLIV2/aws" ]; then
            AWS_CLI="/c/Program Files/Amazon/AWSCLIV2/aws"
        fi
    else
        # On Linux/WSL, try Linux paths first
        if [ -x "/usr/local/bin/aws" ]; then
            AWS_CLI="/usr/local/bin/aws"
        elif [ -x "/usr/bin/aws" ]; then
            AWS_CLI="/usr/bin/aws"
        elif [ -x "/bin/aws" ]; then
            AWS_CLI="/bin/aws"
        else
            # Fallback to command -v but exclude Windows paths on WSL
            TEMP_AWS="$(command -v aws 2>/dev/null || true)"
            if [[ "$TEMP_AWS" != /mnt/c/* ]] && [ -n "$TEMP_AWS" ]; then
                AWS_CLI="$TEMP_AWS"
            fi
        fi
    fi
fi

# Final validation
if [ -z "$AWS_CLI" ]; then
    print_message "$RED" "AWS CLI not found. Please install AWS CLI v2."
    if [[ "$(uname -s)" == MINGW* ]] || [[ "$(uname -s)" == MSYS* ]]; then
        print_message "$YELLOW" "Download from: https://awscli.amazonaws.com/AWSCLIV2.msi"
    else
        print_message "$YELLOW" "Install with:"
        print_message "$YELLOW" "  curl \"https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip\" -o \"awscliv2.zip\""
        print_message "$YELLOW" "  unzip awscliv2.zip"
        print_message "$YELLOW" "  sudo ./aws/install"
    fi
    exit 1
fi

print_message "$GREEN" "Using AWS CLI: $AWS_CLI"

# Check if key name is set
if [ -z "$KEY_NAME" ]; then
    print_message "$RED" "Please set KEY_NAME in the script before running."
    exit 1
fi

print_message "$GREEN" "Starting CareFlowAI infrastructure deployment..."

# 1. Deploy VPC
print_message "$YELLOW" "Deploying VPC..."
VPC_STACK_NAME="${STACK_NAME_PREFIX}-VPC"


update_or_create_stack $VPC_STACK_NAME "$PROJECT_ROOT/aws/cloudformation/vpc.yaml"

# Get VPC ID
VPC_ID=$("$AWS_CLI" cloudformation describe-stacks \
    --stack-name $VPC_STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`VPC`].OutputValue' \
    --output text)

print_message "$GREEN" "VPC ID: $VPC_ID"

# 2. Deploy Security Groups
print_message "$YELLOW" "Deploying Security Groups..."
SG_STACK_NAME="${STACK_NAME_PREFIX}-SecurityGroups"

update_or_create_stack $SG_STACK_NAME "$PROJECT_ROOT/aws/cloudformation/security-groups.yaml" \
    --parameters ParameterKey=VPCId,ParameterValue=$VPC_ID

# Get Security Group ID
SG_ID=$("$AWS_CLI" cloudformation describe-stacks \
    --stack-name $SG_STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`BackendSecurityGroup`].OutputValue' \
    --output text)

print_message "$GREEN" "Security Group ID: $SG_ID"

# Get Subnet ID
SUBNET_ID=$("$AWS_CLI" cloudformation describe-stacks \
    --stack-name $VPC_STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`PublicSubnet1`].OutputValue' \
    --output text)

print_message "$GREEN" "Subnet ID: $SUBNET_ID"

# 3. Deploy EC2 Backend
print_message "$YELLOW" "Deploying EC2 Backend..."
EC2_STACK_NAME="${STACK_NAME_PREFIX}-Backend"

if stack_exists $EC2_STACK_NAME; then
    print_message "$YELLOW" "EC2 stack already exists. Skipping..."
else
    "$AWS_CLI" cloudformation create-stack \
        --stack-name $EC2_STACK_NAME \
        --template-body file://"$PROJECT_ROOT"/aws/cloudformation/ec2-backend.yaml \
        --parameters \
            ParameterKey=KeyName,ParameterValue=$KEY_NAME \
            ParameterKey=InstanceType,ParameterValue=$INSTANCE_TYPE \
            ParameterKey=VPCId,ParameterValue=$VPC_ID \
            ParameterKey=SubnetId,ParameterValue=$SUBNET_ID \
            ParameterKey=SecurityGroupId,ParameterValue=$SG_ID \
        --capabilities CAPABILITY_NAMED_IAM \
        --region $REGION

    wait_for_stack $EC2_STACK_NAME
fi

# Get Elastic IP
ELASTIC_IP=$("$AWS_CLI" cloudformation describe-stacks \
    --stack-name $EC2_STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`ElasticIP`].OutputValue' \
    --output text)

print_message "$GREEN" "Elastic IP: $ELASTIC_IP"

# 4. Deploy S3 and CloudFront
print_message "$YELLOW" "Deploying S3 and CloudFront..."
S3_STACK_NAME="${STACK_NAME_PREFIX}-Frontend"

if stack_exists $S3_STACK_NAME; then
    print_message "$YELLOW" "S3/CloudFront stack already exists. Skipping..."
else
    "$AWS_CLI" cloudformation create-stack \
        --stack-name $S3_STACK_NAME \
        --template-body file://"$PROJECT_ROOT"/aws/cloudformation/s3-cloudfront.yaml \
        --region $REGION

    wait_for_stack $S3_STACK_NAME
fi

# Get S3 Bucket Name and CloudFront Domain
BUCKET_NAME=$("$AWS_CLI" cloudformation describe-stacks \
    --stack-name $S3_STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`FrontendBucketName`].OutputValue' \
    --output text)

CLOUDFRONT_DOMAIN=$("$AWS_CLI" cloudformation describe-stacks \
    --stack-name $S3_STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontDomainName`].OutputValue' \
    --output text)

print_message "$GREEN" "S3 Bucket: $BUCKET_NAME"
print_message "$GREEN" "CloudFront Domain: $CLOUDFRONT_DOMAIN"

# 5. Deploy API Gateway (Optional - requires ALB first)
# Set DEPLOY_API_GATEWAY=yes environment variable to enable
if [[ "$DEPLOY_API_GATEWAY" =~ ^[Yy][Ee][Ss]$|^[Yy]$ ]]; then
    print_message "$YELLOW" "Deploying API Gateway..."
    # Check if ALB stack exists
    ALB_STACK_NAME="${STACK_NAME_PREFIX}-ALB"
    if stack_exists $ALB_STACK_NAME; then
        # Get ALB details
        ALB_ARN=$("$AWS_CLI" cloudformation describe-stacks \
            --stack-name $ALB_STACK_NAME \
            --region $REGION \
            --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerArn`].OutputValue' \
            --output text)

        ALB_DNS=$("$AWS_CLI" cloudformation describe-stacks \
            --stack-name $ALB_STACK_NAME \
            --region $REGION \
            --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
            --output text)

        API_STACK_NAME="${STACK_NAME_PREFIX}-APIGateway"
        SUBNET2=$("$AWS_CLI" cloudformation describe-stacks \
            --stack-name $VPC_STACK_NAME \
            --region $REGION \
            --query 'Stacks[0].Outputs[?OutputKey==`PublicSubnet2`].OutputValue' \
            --output text)

        update_or_create_stack $API_STACK_NAME "$PROJECT_ROOT/aws/cloudformation/api-gateway.yaml" \
            --parameters \
                ParameterKey=VPCId,ParameterValue=$VPC_ID \
                ParameterKey=PublicSubnet1,ParameterValue=$SUBNET_ID \
                ParameterKey=PublicSubnet2,ParameterValue=$SUBNET2 \
                ParameterKey=LoadBalancerArn,ParameterValue=$ALB_ARN \
                ParameterKey=LoadBalancerDNS,ParameterValue=$ALB_DNS \
            --capabilities CAPABILITY_IAM

        # Get API Gateway URL
        API_URL=$("$AWS_CLI" cloudformation describe-stacks \
            --stack-name $API_STACK_NAME \
            --region $REGION \
            --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayStageUrl`].OutputValue' \
            --output text)

        print_message "$GREEN" "API Gateway URL: $API_URL"
    else
        print_message "$YELLOW" "ALB stack not found. Deploy ALB first, then run this script again for API Gateway."
    fi
else
    print_message "$YELLOW" "Skipping API Gateway deployment."
    API_URL="Not deployed"
fi

# Summary
print_message "$GREEN" "\n========================================="
print_message "$GREEN" "Infrastructure Deployment Complete!"
print_message "$GREEN" "========================================="
print_message "$YELLOW" "\nResource Summary:"
echo "VPC ID: $VPC_ID"
echo "Security Group ID: $SG_ID"
echo "EC2 Elastic IP: $ELASTIC_IP"
echo "S3 Bucket: $BUCKET_NAME"
echo "CloudFront Domain: https://$CLOUDFRONT_DOMAIN"
if [[ "$API_URL" != "Not deployed" ]]; then
    echo "API Gateway URL: $API_URL"
fi
print_message "$YELLOW" "\nNext Steps:"
echo "1. SSH into EC2: ssh -i your-key.pem ubuntu@$ELASTIC_IP"
echo "2. Deploy backend application"
echo "3. Deploy frontend to S3"
echo "4. Configure MongoDB Atlas and add Elastic IP to whitelist"
if [[ "$API_URL" != "Not deployed" ]]; then
    echo "5. Test API via API Gateway: curl $API_URL/health"
fi
print_message "$GREEN" "========================================="
