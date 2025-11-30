#!/bin/bash

################################################################################
# AWS CareFlowAI Resource Startup Script
#
# This script starts all AWS resources for CareFlowAI that were previously
# stopped or scaled down to save costs.
#
# Usage: bash startup-aws-resources.sh
################################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration - UPDATE THESE VALUES TO MATCH YOUR DEPLOYMENT
AWS_REGION="us-east-1"
EKS_CLUSTER_NAME="careflowai-cluster"
MONGODB_CLUSTER_NAME="careflowai-mongodb"
VPC_NAME="careflowai-vpc"
CLOUDFORMATION_STACK_PREFIX="CareFlowAI"

echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}         AWS CAREFLOWAI RESOURCE STARTUP SCRIPT                ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}This script will start the following resources:${NC}"
echo "  - CloudFormation stacks (if applicable)"
echo "  - EC2 instances"
echo "  - DocumentDB cluster instances"
echo "  - EKS cluster node groups (if applicable)"
echo ""

# Confirmation prompt
read -p "Do you want to proceed with starting resources? (yes/no): " confirmation
if [ "$confirmation" != "yes" ]; then
    echo -e "${YELLOW}Startup cancelled. No resources were started.${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}Starting resource startup process...${NC}"
echo ""

# Track if any resources were found
RESOURCES_FOUND=false

################################################################################
# 1. Start DocumentDB Cluster
################################################################################
echo -e "${YELLOW}[1/4] Starting DocumentDB cluster...${NC}"

# Check if cluster exists and is stopped
DOCDB_STATUS=$(aws docdb describe-db-clusters \
    --db-cluster-identifier "$MONGODB_CLUSTER_NAME" \
    --region "$AWS_REGION" \
    --query "DBClusters[0].Status" \
    --output text 2>/dev/null || echo "NOT_FOUND")

if [ "$DOCDB_STATUS" = "stopped" ]; then
    echo "Starting DocumentDB cluster: $MONGODB_CLUSTER_NAME"
    aws docdb start-db-cluster \
        --db-cluster-identifier "$MONGODB_CLUSTER_NAME" \
        --region "$AWS_REGION"

    echo "Waiting for DocumentDB cluster to become available..."
    aws docdb wait db-cluster-available \
        --db-cluster-identifier "$MONGODB_CLUSTER_NAME" \
        --region "$AWS_REGION"

    echo -e "${GREEN}✓ DocumentDB cluster started and available${NC}"
    RESOURCES_FOUND=true
elif [ "$DOCDB_STATUS" = "available" ]; then
    echo -e "${GREEN}✓ DocumentDB cluster is already running${NC}"
    RESOURCES_FOUND=true
elif [ "$DOCDB_STATUS" = "NOT_FOUND" ]; then
    echo -e "${YELLOW}⚠ DocumentDB cluster not found, skipping...${NC}"
else
    echo -e "${YELLOW}⚠ DocumentDB cluster is in state: $DOCDB_STATUS${NC}"
    RESOURCES_FOUND=true
fi

echo ""

################################################################################
# 2. Start EC2 Instances
################################################################################
echo -e "${YELLOW}[2/4] Starting EC2 instances...${NC}"

# Get EC2 instance from CloudFormation stack
EC2_STACK_NAME="${CLOUDFORMATION_STACK_PREFIX}-Backend"

if aws cloudformation describe-stacks --stack-name "$EC2_STACK_NAME" --region "$AWS_REGION" &>/dev/null; then
    INSTANCE_ID=$(aws cloudformation describe-stacks \
        --stack-name "$EC2_STACK_NAME" \
        --region "$AWS_REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`InstanceId`].OutputValue' \
        --output text 2>/dev/null)

    if [ -n "$INSTANCE_ID" ] && [ "$INSTANCE_ID" != "None" ]; then
        # Check instance state
        INSTANCE_STATE=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --region "$AWS_REGION" \
            --query 'Reservations[0].Instances[0].State.Name' \
            --output text 2>/dev/null || echo "NOT_FOUND")

        if [ "$INSTANCE_STATE" = "stopped" ]; then
            echo "Starting EC2 instance: $INSTANCE_ID"
            aws ec2 start-instances \
                --instance-ids "$INSTANCE_ID" \
                --region "$AWS_REGION"

            echo "Waiting for instance to be running..."
            aws ec2 wait instance-running \
                --instance-ids "$INSTANCE_ID" \
                --region "$AWS_REGION"

            # Get public IP
            PUBLIC_IP=$(aws ec2 describe-instances \
                --instance-ids "$INSTANCE_ID" \
                --region "$AWS_REGION" \
                --query 'Reservations[0].Instances[0].PublicIpAddress' \
                --output text)

            echo -e "${GREEN}✓ EC2 instance started${NC}"
            echo -e "${GREEN}  Instance ID: $INSTANCE_ID${NC}"
            echo -e "${GREEN}  Public IP: $PUBLIC_IP${NC}"
            RESOURCES_FOUND=true
        elif [ "$INSTANCE_STATE" = "running" ]; then
            PUBLIC_IP=$(aws ec2 describe-instances \
                --instance-ids "$INSTANCE_ID" \
                --region "$AWS_REGION" \
                --query 'Reservations[0].Instances[0].PublicIpAddress' \
                --output text)
            echo -e "${GREEN}✓ EC2 instance is already running${NC}"
            echo -e "${GREEN}  Instance ID: $INSTANCE_ID${NC}"
            echo -e "${GREEN}  Public IP: $PUBLIC_IP${NC}"
            RESOURCES_FOUND=true
        else
            echo -e "${YELLOW}⚠ EC2 instance is in state: $INSTANCE_STATE${NC}"
            RESOURCES_FOUND=true
        fi
    else
        echo -e "${YELLOW}⚠ No EC2 instance found in CloudFormation stack${NC}"
    fi
else
    # Try to find instances by tag
    echo "CloudFormation stack not found, searching for instances by tag..."

    INSTANCE_IDS=$(aws ec2 describe-instances \
        --region "$AWS_REGION" \
        --filters "Name=tag:Name,Values=*CareFlowAI*" "Name=instance-state-name,Values=stopped" \
        --query 'Reservations[*].Instances[*].InstanceId' \
        --output text 2>/dev/null || true)

    if [ -n "$INSTANCE_IDS" ]; then
        for instance in $INSTANCE_IDS; do
            echo "Starting EC2 instance: $instance"
            aws ec2 start-instances \
                --instance-ids "$instance" \
                --region "$AWS_REGION"
        done

        echo "Waiting for instances to be running..."
        for instance in $INSTANCE_IDS; do
            aws ec2 wait instance-running \
                --instance-ids "$instance" \
                --region "$AWS_REGION"

            PUBLIC_IP=$(aws ec2 describe-instances \
                --instance-ids "$instance" \
                --region "$AWS_REGION" \
                --query 'Reservations[0].Instances[0].PublicIpAddress' \
                --output text)

            echo -e "${GREEN}✓ Instance $instance started - Public IP: $PUBLIC_IP${NC}"
            RESOURCES_FOUND=true
        done
    else
        echo -e "${YELLOW}⚠ No stopped EC2 instances found${NC}"
    fi
fi

echo ""

################################################################################
# 3. Start EKS Node Groups (if applicable)
################################################################################
echo -e "${YELLOW}[3/4] Checking EKS cluster...${NC}"

if aws eks describe-cluster --name "$EKS_CLUSTER_NAME" --region "$AWS_REGION" &>/dev/null; then
    echo "EKS cluster found: $EKS_CLUSTER_NAME"

    # Get node groups
    NODE_GROUPS=$(aws eks list-nodegroups \
        --cluster-name "$EKS_CLUSTER_NAME" \
        --region "$AWS_REGION" \
        --query 'nodegroups[]' \
        --output text 2>/dev/null || true)

    if [ -n "$NODE_GROUPS" ]; then
        for ng in $NODE_GROUPS; do
            echo "Checking node group: $ng"

            # Get current scaling config
            DESIRED_SIZE=$(aws eks describe-nodegroup \
                --cluster-name "$EKS_CLUSTER_NAME" \
                --nodegroup-name "$ng" \
                --region "$AWS_REGION" \
                --query 'nodegroup.scalingConfig.desiredSize' \
                --output text)

            if [ "$DESIRED_SIZE" = "0" ]; then
                echo "Scaling up node group: $ng"
                # Scale to minimum 2 nodes
                aws eks update-nodegroup-config \
                    --cluster-name "$EKS_CLUSTER_NAME" \
                    --nodegroup-name "$ng" \
                    --scaling-config minSize=2,maxSize=4,desiredSize=2 \
                    --region "$AWS_REGION"

                echo -e "${GREEN}✓ Node group $ng scaling initiated${NC}"
            else
                echo -e "${GREEN}✓ Node group $ng already has $DESIRED_SIZE nodes${NC}"
            fi
        done
    else
        echo -e "${YELLOW}⚠ No node groups found in cluster${NC}"
    fi

    echo -e "${GREEN}✓ EKS cluster check complete${NC}"
else
    echo -e "${YELLOW}⚠ EKS cluster not found, skipping...${NC}"
fi

echo ""

################################################################################
# 4. Verify Services
################################################################################
echo -e "${YELLOW}[4/4] Verifying services...${NC}"

# Check if backend service is responding (if EC2 exists)
if [ -n "$PUBLIC_IP" ] && [ "$PUBLIC_IP" != "None" ]; then
    echo "Waiting for backend service to be ready (this may take a few minutes)..."
    sleep 30

    # Try to connect to health endpoint
    if curl -s -o /dev/null -w "%{http_code}" "http://$PUBLIC_IP:8000/health" | grep -q "200"; then
        echo -e "${GREEN}✓ Backend service is responding${NC}"
    else
        echo -e "${YELLOW}⚠ Backend service is not yet responding. It may still be starting up.${NC}"
        echo -e "${YELLOW}  Check manually: http://$PUBLIC_IP:8000/health${NC}"
    fi
fi

# Get CloudFront distribution status
S3_STACK_NAME="${CLOUDFORMATION_STACK_PREFIX}-Frontend"

if aws cloudformation describe-stacks --stack-name "$S3_STACK_NAME" --region "$AWS_REGION" &>/dev/null; then
    CLOUDFRONT_DOMAIN=$(aws cloudformation describe-stacks \
        --stack-name "$S3_STACK_NAME" \
        --region "$AWS_REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontDomainName`].OutputValue' \
        --output text 2>/dev/null)

    if [ -n "$CLOUDFRONT_DOMAIN" ]; then
        echo -e "${GREEN}✓ CloudFront distribution available${NC}"
        echo -e "${GREEN}  URL: https://$CLOUDFRONT_DOMAIN${NC}"
    fi
fi

echo ""

################################################################################
# Startup Complete
################################################################################
echo ""

# Check if any resources were found
if [ "$RESOURCES_FOUND" = false ]; then
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}         NO AWS RESOURCES FOUND                             ${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}It appears you haven't deployed the CareFlowAI infrastructure yet.${NC}"
    echo ""
    echo -e "${BLUE}To deploy the infrastructure, follow these steps:${NC}"
    echo ""
    echo -e "${GREEN}1. Deploy infrastructure using CloudFormation:${NC}"
    echo "   cd aws/scripts"
    echo "   bash deploy-infrastructure.sh"
    echo ""
    echo -e "${GREEN}2. Or check the deployment guides:${NC}"
    echo "   - AWS_DEPLOYMENT_GUIDE.md"
    echo "   - aws/README.md"
    echo ""
    echo -e "${BLUE}If you have resources in a different region:${NC}"
    echo "   Edit the AWS_REGION variable in this script (currently: $AWS_REGION)"
    echo ""
    exit 0
fi

echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}         STARTUP COMPLETED SUCCESSFULLY                        ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Resource Summary:${NC}"

# Print all active resources
if [ -n "$INSTANCE_ID" ] && [ "$INSTANCE_ID" != "None" ]; then
    echo -e "${GREEN}Backend EC2:${NC}"
    echo "  Instance ID: $INSTANCE_ID"
    echo "  Public IP: $PUBLIC_IP"
    echo "  Backend URL: http://$PUBLIC_IP:8000"
    echo "  Health Check: http://$PUBLIC_IP:8000/health"
    echo "  API Docs: http://$PUBLIC_IP:8000/docs"
    echo ""
fi

if [ -n "$CLOUDFRONT_DOMAIN" ]; then
    echo -e "${GREEN}Frontend:${NC}"
    echo "  CloudFront URL: https://$CLOUDFRONT_DOMAIN"
    echo ""
fi

if [ "$DOCDB_STATUS" = "available" ] || [ "$DOCDB_STATUS" = "stopped" ]; then
    DOCDB_ENDPOINT=$(aws docdb describe-db-clusters \
        --db-cluster-identifier "$MONGODB_CLUSTER_NAME" \
        --region "$AWS_REGION" \
        --query 'DBClusters[0].Endpoint' \
        --output text 2>/dev/null || echo "N/A")

    echo -e "${GREEN}DocumentDB:${NC}"
    echo "  Cluster: $MONGODB_CLUSTER_NAME"
    echo "  Endpoint: $DOCDB_ENDPOINT"
    echo ""
fi

echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. Verify backend API: curl http://$PUBLIC_IP:8000/health"
echo "  2. Test frontend application in browser"
echo "  3. Check application logs if needed"
echo ""
echo -e "${BLUE}To SSH into backend:${NC}"
echo "  ssh -i your-key.pem ubuntu@$PUBLIC_IP"
echo ""
echo -e "${YELLOW}Note: Services may take a few minutes to fully initialize.${NC}"
echo ""
