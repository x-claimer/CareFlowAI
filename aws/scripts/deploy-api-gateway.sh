#!/bin/bash

###############################################################################
# CareFlowAI API Gateway Deployment Script
# Deploys API Gateway and connects it to the Application Load Balancer
###############################################################################

set -e

# Determine PROJECT_ROOT
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Load environment variables from .env file
if [ -f "$PROJECT_ROOT/aws/.env" ]; then
    export $(grep -v '^#' "$PROJECT_ROOT/aws/.env" | grep -v '^$' | xargs)
    echo "Loaded configuration from $PROJECT_ROOT/aws/.env"
else
    echo "Warning: .env file not found at $PROJECT_ROOT/aws/.env"
fi

# Configuration with defaults from .env or hardcoded fallbacks
STACK_NAME_PREFIX="${STACK_NAME_PREFIX:-CareFlowAI}"
REGION="${REGION:-us-east-1}"
AWS_CLI="${AWS_CLI:-}"

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

# Function to wait for stack completion
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

print_message "$GREEN" "Starting API Gateway deployment..."

# Check prerequisites
VPC_STACK_NAME="${STACK_NAME_PREFIX}-VPC"
ALB_STACK_NAME="${STACK_NAME_PREFIX}-ALB"

if ! stack_exists $VPC_STACK_NAME; then
    print_message "$RED" "VPC stack not found! Deploy VPC first using deploy-infrastructure.sh"
    exit 1
fi

if ! stack_exists $ALB_STACK_NAME; then
    print_message "$RED" "ALB stack not found! Deploy ALB first."
    print_message "$YELLOW" "Hint: You need to deploy the complete infrastructure with ALB before API Gateway."
    exit 1
fi

# Get VPC details
VPC_ID=$("$AWS_CLI" cloudformation describe-stacks \
    --stack-name $VPC_STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`VPC`].OutputValue' \
    --output text)

PUBLIC_SUBNET_1=$("$AWS_CLI" cloudformation describe-stacks \
    --stack-name $VPC_STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`PublicSubnet1`].OutputValue' \
    --output text)

PUBLIC_SUBNET_2=$("$AWS_CLI" cloudformation describe-stacks \
    --stack-name $VPC_STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`PublicSubnet2`].OutputValue' \
    --output text)

print_message "$GREEN" "VPC ID: $VPC_ID"
print_message "$GREEN" "Public Subnet 1: $PUBLIC_SUBNET_1"
print_message "$GREEN" "Public Subnet 2: $PUBLIC_SUBNET_2"

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

print_message "$GREEN" "ALB ARN: $ALB_ARN"
print_message "$GREEN" "ALB DNS: $ALB_DNS"

# Deploy API Gateway
print_message "$YELLOW" "Deploying API Gateway stack..."
API_STACK_NAME="${STACK_NAME_PREFIX}-APIGateway"

if stack_exists $API_STACK_NAME; then
    print_message "$YELLOW" "API Gateway stack already exists. Updating..."
    "$AWS_CLI" cloudformation update-stack \
        --stack-name $API_STACK_NAME \
        --template-body file://"$PROJECT_ROOT"/aws/cloudformation/api-gateway.yaml \
        --parameters \
            ParameterKey=VPCId,ParameterValue=$VPC_ID \
            ParameterKey=PublicSubnet1,ParameterValue=$PUBLIC_SUBNET_1 \
            ParameterKey=PublicSubnet2,ParameterValue=$PUBLIC_SUBNET_2 \
            ParameterKey=LoadBalancerArn,ParameterValue=$ALB_ARN \
            ParameterKey=LoadBalancerDNS,ParameterValue=$ALB_DNS \
        --region $REGION \
        --capabilities CAPABILITY_IAM

    print_message "$YELLOW" "Waiting for stack update to complete..."
    "$AWS_CLI" cloudformation wait stack-update-complete \
        --stack-name $API_STACK_NAME \
        --region $REGION
    print_message "$GREEN" "Stack updated successfully!"
else
    "$AWS_CLI" cloudformation create-stack \
        --stack-name $API_STACK_NAME \
        --template-body file://"$PROJECT_ROOT"/aws/cloudformation/api-gateway.yaml \
        --parameters \
            ParameterKey=VPCId,ParameterValue=$VPC_ID \
            ParameterKey=PublicSubnet1,ParameterValue=$PUBLIC_SUBNET_1 \
            ParameterKey=PublicSubnet2,ParameterValue=$PUBLIC_SUBNET_2 \
            ParameterKey=LoadBalancerArn,ParameterValue=$ALB_ARN \
            ParameterKey=LoadBalancerDNS,ParameterValue=$ALB_DNS \
        --region $REGION \
        --capabilities CAPABILITY_IAM

    wait_for_stack $API_STACK_NAME
fi

# Get API Gateway outputs
API_ID=$("$AWS_CLI" cloudformation describe-stacks \
    --stack-name $API_STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayId`].OutputValue' \
    --output text)

API_ENDPOINT=$("$AWS_CLI" cloudformation describe-stacks \
    --stack-name $API_STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayEndpoint`].OutputValue' \
    --output text)

API_URL=$("$AWS_CLI" cloudformation describe-stacks \
    --stack-name $API_STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayStageUrl`].OutputValue' \
    --output text)

VPC_LINK_ID=$("$AWS_CLI" cloudformation describe-stacks \
    --stack-name $API_STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`VPCLinkId`].OutputValue' \
    --output text)

# Summary
print_message "$GREEN" "\n========================================="
print_message "$GREEN" "API Gateway Deployment Complete!"
print_message "$GREEN" "========================================="
print_message "$YELLOW" "\nResource Summary:"
echo "API Gateway ID: $API_ID"
echo "API Endpoint: $API_ENDPOINT"
echo "API URL (prod): $API_URL"
echo "VPC Link ID: $VPC_LINK_ID"
echo ""
print_message "$YELLOW" "Next Steps:"
echo "1. Test API health endpoint:"
echo "   curl $API_URL/health"
echo ""
echo "2. Update frontend to use API Gateway URL:"
echo "   VITE_API_URL=$API_URL"
echo ""
echo "3. Test API endpoints:"
echo "   curl $API_URL/api/users"
echo "   curl $API_URL/docs"
print_message "$GREEN" "========================================="
