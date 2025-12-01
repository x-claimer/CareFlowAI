#!/bin/bash

###############################################################################
# CareFlowAI Infrastructure Deployment Script
# This script deploys the complete AWS infrastructure using CloudFormation
###############################################################################

set -e  # Exit on error

# Configuration
STACK_NAME_PREFIX="CareFlowAI"
REGION="us-east-1"
KEY_NAME="CareFlowAI-Key-New"  # Set your EC2 key pair name
INSTANCE_TYPE="t2.micro"  # Options: t2.micro, t3.small, t3.medium
# Override to point to a specific aws binary if needed.
# If not provided, we try to pick a Linux binary even if PATH points to /mnt/c/...
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

# Resolve AWS CLI path, preferring a Linux binary over a Windows path
if [ -z "$AWS_CLI" ]; then
    if command -v /usr/bin/aws >/dev/null 2>&1; then
        AWS_CLI="/usr/bin/aws"
    else
        AWS_CLI="$(command -v aws || true)"
    fi
fi

if [[ "$AWS_CLI" == /mnt/c/* ]]; then
    print_message "$YELLOW" "Detected Windows AWS CLI path ($AWS_CLI); trying Linux aws instead"
    if command -v /usr/bin/aws >/dev/null 2>&1; then
        AWS_CLI="/usr/bin/aws"
    elif command -v aws >/dev/null 2>&1; then
        AWS_CLI="$(command -v aws)"
    fi
fi

if [ -z "$AWS_CLI" ] || ! command -v "$AWS_CLI" >/dev/null 2>&1; then
    print_message "$RED" "AWS CLI not found. Install AWS CLI v2 for Linux or set AWS_CLI to the correct binary."
    exit 1
fi

# Check if key name is set
if [ -z "$KEY_NAME" ]; then
    print_message "$RED" "Please set KEY_NAME in the script before running."
    exit 1
fi

print_message "$GREEN" "Starting CareFlowAI infrastructure deployment..."

# 1. Deploy VPC
print_message "$YELLOW" "Deploying VPC..."
VPC_STACK_NAME="${STACK_NAME_PREFIX}-VPC"

if stack_exists $VPC_STACK_NAME; then
    print_message "$YELLOW" "VPC stack already exists. Updating..."
    "$AWS_CLI" cloudformation update-stack \
        --stack-name $VPC_STACK_NAME \
        --template-body file://aws/cloudformation/vpc.yaml \
        --region $REGION
else
    "$AWS_CLI" cloudformation create-stack \
        --stack-name $VPC_STACK_NAME \
        --template-body file://aws/cloudformation/vpc.yaml \
        --region $REGION

    wait_for_stack $VPC_STACK_NAME
fi

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

if stack_exists $SG_STACK_NAME; then
    print_message "$YELLOW" "Security Groups stack already exists. Updating..."
    "$AWS_CLI" cloudformation update-stack \
        --stack-name $SG_STACK_NAME \
        --template-body file://aws/cloudformation/security-groups.yaml \
        --parameters ParameterKey=VPCId,ParameterValue=$VPC_ID \
        --region $REGION
else
    "$AWS_CLI" cloudformation create-stack \
        --stack-name $SG_STACK_NAME \
        --template-body file://aws/cloudformation/security-groups.yaml \
        --parameters ParameterKey=VPCId,ParameterValue=$VPC_ID \
        --region $REGION

    wait_for_stack $SG_STACK_NAME
fi

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
        --template-body file://aws/cloudformation/ec2-backend.yaml \
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
        --template-body file://aws/cloudformation/s3-cloudfront.yaml \
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
print_message "$YELLOW" "\nNext Steps:"
echo "1. SSH into EC2: ssh -i your-key.pem ubuntu@$ELASTIC_IP"
echo "2. Deploy backend application"
echo "3. Deploy frontend to S3"
echo "4. Configure MongoDB Atlas and add Elastic IP to whitelist"
print_message "$GREEN" "========================================="
