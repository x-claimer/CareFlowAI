#!/bin/bash

################################################################################
# AWS CareFlowAI Resource Cleanup Script
#
# WARNING: This script will DELETE all AWS resources created for CareFlowAI
# This action is IRREVERSIBLE and will result in:
# - Deletion of all application data
# - Removal of all infrastructure
# - Loss of all configurations
#
# ONLY run this script when you are absolutely certain you want to
# completely remove the CareFlowAI deployment from AWS
#
# Usage: bash cleanup-aws-resources.sh
################################################################################

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

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration with defaults from .env or hardcoded fallbacks
AWS_REGION="${AWS_REGION:-us-east-1}"
EKS_CLUSTER_NAME="${EKS_CLUSTER_NAME:-careflowai-cluster}"
ECR_REPOSITORY_FRONTEND="${ECR_REPOSITORY_FRONTEND:-careflowai-frontend}"
ECR_REPOSITORY_BACKEND="${ECR_REPOSITORY_BACKEND:-careflowai-backend}"
MONGODB_CLUSTER_NAME="${MONGODB_CLUSTER_NAME:-careflowai-mongodb}"
VPC_NAME="${VPC_NAME:-careflowai-vpc}"
LOAD_BALANCER_NAME="${LOAD_BALANCER_NAME:-careflowai-alb}"
S3_BUCKET_NAME="${S3_BUCKET_NAME:-careflowai-static-assets}"
IAM_ROLE_PREFIX="${IAM_ROLE_PREFIX:-careflowai}"

echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${RED}         AWS CAREFLOWAI RESOURCE CLEANUP SCRIPT                ${NC}"
echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}WARNING: This will DELETE ALL AWS resources for CareFlowAI${NC}"
echo -e "${YELLOW}This includes:${NC}"
echo "  - CloudFormation Stacks"
echo "  - EC2 Instances (running and stopped)"
echo "  - CloudFront Distributions"
echo "  - S3 buckets and stored files"
echo "  - Load Balancers and Target Groups"
echo "  - VPC, Subnets, and Network configurations"
echo "  - IAM roles and policies"
echo "  - Security Groups"
echo ""
echo -e "${RED}THIS ACTION CANNOT BE UNDONE!${NC}"
echo ""

# Confirmation prompt
read -p "Type 'DELETE-CAREFLOWAI' to confirm deletion: " confirmation
if [ "$confirmation" != "DELETE-CAREFLOWAI" ]; then
    echo -e "${GREEN}Cleanup cancelled. No resources were deleted.${NC}"
    exit 0
fi

echo ""
read -p "Are you absolutely sure? Type 'YES' to proceed: " final_confirmation
if [ "$final_confirmation" != "YES" ]; then
    echo -e "${GREEN}Cleanup cancelled. No resources were deleted.${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}Starting cleanup process...${NC}"
echo ""

################################################################################
# 1. Delete CloudFront Distributions
################################################################################
echo -e "${YELLOW}[1/8] Deleting CloudFront distributions...${NC}"

CF_DISTROS=$(aws cloudfront list-distributions \
    --query 'DistributionList.Items[*].Id' \
    --output text 2>/dev/null || true)

if [ -n "$CF_DISTROS" ]; then
    for distro_id in $CF_DISTROS; do
        echo "Disabling CloudFront distribution: $distro_id"

        # Get current ETag
        ETAG=$(aws cloudfront get-distribution --id "$distro_id" \
            --query 'ETag' --output text 2>/dev/null || true)

        # Get current config and disable it
        aws cloudfront get-distribution-config --id "$distro_id" \
            --output json 2>/dev/null | \
            jq '.DistributionConfig | .Enabled = false' > /tmp/distro-config.json 2>/dev/null || true

        # Update distribution to disable it
        aws cloudfront update-distribution \
            --id "$distro_id" \
            --distribution-config file:///tmp/distro-config.json \
            --if-match "$ETAG" 2>/dev/null || true

        echo "Waiting for distribution $distro_id to be disabled (this may take 10-20 minutes)..."
        aws cloudfront wait distribution-deployed --id "$distro_id" 2>/dev/null || true

        # Get new ETag after update
        ETAG=$(aws cloudfront get-distribution --id "$distro_id" \
            --query 'ETag' --output text 2>/dev/null || true)

        echo "Deleting CloudFront distribution: $distro_id"
        aws cloudfront delete-distribution \
            --id "$distro_id" \
            --if-match "$ETAG" 2>/dev/null || true
    done
else
    echo "No CloudFront distributions found, skipping..."
fi

echo -e "${GREEN}✓ CloudFront distributions deleted${NC}"
echo ""

################################################################################
# 2. Terminate EC2 Instances
################################################################################
echo -e "${YELLOW}[2/8] Terminating EC2 instances...${NC}"

INSTANCE_IDS=$(aws ec2 describe-instances \
    --region "$AWS_REGION" \
    --query 'Reservations[*].Instances[?State.Name!=`terminated`].InstanceId' \
    --output text 2>/dev/null || true)

if [ -n "$INSTANCE_IDS" ]; then
    echo "Found instances to terminate: $INSTANCE_IDS"
    for instance_id in $INSTANCE_IDS; do
        echo "Terminating instance: $instance_id"
        aws ec2 terminate-instances \
            --instance-ids "$instance_id" \
            --region "$AWS_REGION" 2>/dev/null || true
    done

    echo "Waiting for instances to terminate..."
    aws ec2 wait instance-terminated \
        --instance-ids $INSTANCE_IDS \
        --region "$AWS_REGION" 2>/dev/null || true
else
    echo "No EC2 instances found, skipping..."
fi

echo -e "${GREEN}✓ EC2 instances terminated${NC}"
echo ""

################################################################################
# 3. Delete Load Balancers
################################################################################
echo -e "${YELLOW}[3/8] Deleting load balancers...${NC}"

# Get all load balancers with careflowai tag
LB_ARNS=$(aws elbv2 describe-load-balancers \
    --region "$AWS_REGION" \
    --query "LoadBalancers[?contains(LoadBalancerName, 'careflowai')].LoadBalancerArn" \
    --output text 2>/dev/null || true)

for lb_arn in $LB_ARNS; do
    echo "Deleting load balancer: $lb_arn"
    aws elbv2 delete-load-balancer \
        --load-balancer-arn "$lb_arn" \
        --region "$AWS_REGION" 2>/dev/null || true
done

# Wait for load balancers to be deleted
echo "Waiting for load balancers to be deleted..."
sleep 30

# Delete target groups
TG_ARNS=$(aws elbv2 describe-target-groups \
    --region "$AWS_REGION" \
    --query "TargetGroups[?contains(TargetGroupName, 'careflowai')].TargetGroupArn" \
    --output text 2>/dev/null || true)

for tg_arn in $TG_ARNS; do
    echo "Deleting target group: $tg_arn"
    aws elbv2 delete-target-group \
        --target-group-arn "$tg_arn" \
        --region "$AWS_REGION" 2>/dev/null || true
done

echo -e "${GREEN}✓ Load balancers deleted${NC}"
echo ""

################################################################################
# 4. Delete S3 Buckets
################################################################################
echo -e "${YELLOW}[4/8] Deleting S3 buckets...${NC}"

# Get all S3 buckets with careflow in name
S3_BUCKETS=$(aws s3 ls 2>/dev/null | grep -i careflow | awk '{print $3}')

if [ -n "$S3_BUCKETS" ]; then
    for bucket in $S3_BUCKETS; do
        echo "Processing S3 bucket: $bucket"

        # Check if bucket exists
        if aws s3 ls "s3://$bucket" --region "$AWS_REGION" &>/dev/null; then
            echo "  Emptying bucket contents..."
            aws s3 rm "s3://$bucket" --recursive --region "$AWS_REGION" 2>/dev/null || true

            # Delete any versioned objects if versioning is enabled
            echo "  Checking for versioned objects..."
            aws s3api delete-objects \
                --bucket "$bucket" \
                --delete "$(aws s3api list-object-versions \
                    --bucket "$bucket" \
                    --region "$AWS_REGION" \
                    --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' \
                    --max-items 1000)" \
                --region "$AWS_REGION" 2>/dev/null || true

            # Delete delete markers
            echo "  Checking for delete markers..."
            aws s3api delete-objects \
                --bucket "$bucket" \
                --delete "$(aws s3api list-object-versions \
                    --bucket "$bucket" \
                    --region "$AWS_REGION" \
                    --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' \
                    --max-items 1000)" \
                --region "$AWS_REGION" 2>/dev/null || true

            echo "  Deleting bucket: $bucket"
            aws s3 rb "s3://$bucket" --force --region "$AWS_REGION" 2>/dev/null || true

            # Verify deletion
            if aws s3 ls "s3://$bucket" --region "$AWS_REGION" &>/dev/null; then
                echo "  ${RED}Warning: Bucket $bucket still exists${NC}"
            else
                echo "  ${GREEN}✓ Bucket $bucket deleted successfully${NC}"
            fi
        else
            echo "  Bucket $bucket not found or already deleted"
        fi
        echo ""
    done
else
    echo "No S3 buckets with 'careflow' in name found, skipping..."
fi

echo -e "${GREEN}✓ S3 bucket cleanup completed${NC}"
echo ""

################################################################################
# 5. Delete NAT Gateways and Elastic IPs
################################################################################
echo -e "${YELLOW}[5/8] Deleting NAT gateways and Elastic IPs...${NC}"

# Get VPC ID
VPC_ID=$(aws ec2 describe-vpcs \
    --region "$AWS_REGION" \
    --filters "Name=tag:Name,Values=$VPC_NAME" \
    --query "Vpcs[0].VpcId" \
    --output text 2>/dev/null || true)

if [ "$VPC_ID" != "None" ] && [ -n "$VPC_ID" ]; then
    # Delete NAT Gateways
    NAT_GATEWAYS=$(aws ec2 describe-nat-gateways \
        --region "$AWS_REGION" \
        --filter "Name=vpc-id,Values=$VPC_ID" \
        --query "NatGateways[?State!='deleted'].NatGatewayId" \
        --output text 2>/dev/null || true)

    for nat in $NAT_GATEWAYS; do
        echo "Deleting NAT Gateway: $nat"
        aws ec2 delete-nat-gateway \
            --nat-gateway-id "$nat" \
            --region "$AWS_REGION" 2>/dev/null || true
    done

    # Wait for NAT gateways to be deleted
    if [ -n "$NAT_GATEWAYS" ]; then
        echo "Waiting for NAT gateways to be deleted..."
        sleep 60
    fi

    # Release Elastic IPs
    EIP_ALLOCS=$(aws ec2 describe-addresses \
        --region "$AWS_REGION" \
        --filters "Name=domain,Values=vpc" \
        --query "Addresses[?contains(Tags[?Key=='Name'].Value, 'careflowai')].AllocationId" \
        --output text 2>/dev/null || true)

    for eip in $EIP_ALLOCS; do
        echo "Releasing Elastic IP: $eip"
        aws ec2 release-address \
            --allocation-id "$eip" \
            --region "$AWS_REGION" 2>/dev/null || true
    done
fi

echo -e "${GREEN}✓ NAT gateways and Elastic IPs deleted${NC}"
echo ""

################################################################################
# 6. Delete VPC and Network Resources
################################################################################
echo -e "${YELLOW}[6/8] Deleting VPC and network resources...${NC}"

if [ "$VPC_ID" != "None" ] && [ -n "$VPC_ID" ]; then
    echo "Deleting resources in VPC: $VPC_ID"

    # Delete Internet Gateways
    IGW_IDS=$(aws ec2 describe-internet-gateways \
        --region "$AWS_REGION" \
        --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
        --query "InternetGateways[].InternetGatewayId" \
        --output text 2>/dev/null || true)

    for igw in $IGW_IDS; do
        echo "Detaching and deleting Internet Gateway: $igw"
        aws ec2 detach-internet-gateway \
            --internet-gateway-id "$igw" \
            --vpc-id "$VPC_ID" \
            --region "$AWS_REGION" 2>/dev/null || true
        aws ec2 delete-internet-gateway \
            --internet-gateway-id "$igw" \
            --region "$AWS_REGION" 2>/dev/null || true
    done

    # Delete Subnets
    SUBNET_IDS=$(aws ec2 describe-subnets \
        --region "$AWS_REGION" \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query "Subnets[].SubnetId" \
        --output text 2>/dev/null || true)

    for subnet in $SUBNET_IDS; do
        echo "Deleting subnet: $subnet"
        aws ec2 delete-subnet \
            --subnet-id "$subnet" \
            --region "$AWS_REGION" 2>/dev/null || true
    done

    # Delete Route Tables (except main)
    ROUTE_TABLE_IDS=$(aws ec2 describe-route-tables \
        --region "$AWS_REGION" \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query "RouteTables[?Associations[0].Main!=\`true\`].RouteTableId" \
        --output text 2>/dev/null || true)

    for rt in $ROUTE_TABLE_IDS; do
        echo "Deleting route table: $rt"
        aws ec2 delete-route-table \
            --route-table-id "$rt" \
            --region "$AWS_REGION" 2>/dev/null || true
    done

    # Delete Security Groups (except default)
    SECURITY_GROUP_IDS=$(aws ec2 describe-security-groups \
        --region "$AWS_REGION" \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query "SecurityGroups[?GroupName!='default'].GroupId" \
        --output text 2>/dev/null || true)

    for sg in $SECURITY_GROUP_IDS; do
        echo "Deleting security group: $sg"
        aws ec2 delete-security-group \
            --group-id "$sg" \
            --region "$AWS_REGION" 2>/dev/null || true
    done

    # Delete VPC
    echo "Deleting VPC: $VPC_ID"
    aws ec2 delete-vpc \
        --vpc-id "$VPC_ID" \
        --region "$AWS_REGION" 2>/dev/null || true
else
    echo "VPC not found, skipping..."
fi

echo -e "${GREEN}✓ VPC and network resources deleted${NC}"
echo ""

################################################################################
# 7. Delete IAM Roles and Policies
################################################################################
echo -e "${YELLOW}[7/8] Deleting IAM roles and policies...${NC}"

# Delete EKS cluster role
for role in "${IAM_ROLE_PREFIX}-eks-cluster-role" "${IAM_ROLE_PREFIX}-eks-node-role" "${IAM_ROLE_PREFIX}-pod-role"; do
    if aws iam get-role --role-name "$role" &>/dev/null; then
        echo "Detaching policies from role: $role"

        # Detach managed policies
        ATTACHED_POLICIES=$(aws iam list-attached-role-policies \
            --role-name "$role" \
            --query "AttachedPolicies[].PolicyArn" \
            --output text 2>/dev/null || true)

        for policy in $ATTACHED_POLICIES; do
            aws iam detach-role-policy \
                --role-name "$role" \
                --policy-arn "$policy" 2>/dev/null || true
        done

        # Delete inline policies
        INLINE_POLICIES=$(aws iam list-role-policies \
            --role-name "$role" \
            --query "PolicyNames[]" \
            --output text 2>/dev/null || true)

        for policy in $INLINE_POLICIES; do
            aws iam delete-role-policy \
                --role-name "$role" \
                --policy-name "$policy" 2>/dev/null || true
        done

        # Delete role
        echo "Deleting IAM role: $role"
        aws iam delete-role --role-name "$role" 2>/dev/null || true
    fi
done

# Delete custom IAM policies
CUSTOM_POLICIES=$(aws iam list-policies \
    --scope Local \
    --query "Policies[?contains(PolicyName, '$IAM_ROLE_PREFIX')].Arn" \
    --output text 2>/dev/null || true)

for policy in $CUSTOM_POLICIES; do
    echo "Deleting IAM policy: $policy"

    # Delete all policy versions except default
    VERSIONS=$(aws iam list-policy-versions \
        --policy-arn "$policy" \
        --query "Versions[?IsDefaultVersion==\`false\`].VersionId" \
        --output text 2>/dev/null || true)

    for version in $VERSIONS; do
        aws iam delete-policy-version \
            --policy-arn "$policy" \
            --version-id "$version" 2>/dev/null || true
    done

    aws iam delete-policy --policy-arn "$policy" 2>/dev/null || true
done

echo -e "${GREEN}✓ IAM roles and policies deleted${NC}"
echo ""

################################################################################
# 8. Delete CloudFormation Stacks
################################################################################
echo -e "${YELLOW}[8/8] Deleting CloudFormation stacks...${NC}"

# Get all CareFlow CloudFormation stacks
CF_STACKS=$(aws cloudformation list-stacks \
    --region "$AWS_REGION" \
    --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE ROLLBACK_COMPLETE UPDATE_ROLLBACK_COMPLETE CREATE_FAILED UPDATE_FAILED \
    --query 'StackSummaries[?contains(StackName, `CareFlow`) || contains(StackName, `careflow`)].StackName' \
    --output text 2>/dev/null || true)

if [ -n "$CF_STACKS" ]; then
    # Delete stacks in reverse order (APIGateway, Backend, Frontend, Infrastructure, SecurityGroups, VPC)
    STACK_ORDER="CareFlowAI-APIGateway CareFlowAI-Backend CareFlowAI-Frontend CareFlowAI-Infrastructure CareFlowAI-SecurityGroups CareFlowAI-VPC"

    for stack in $STACK_ORDER; do
        if echo "$CF_STACKS" | grep -q "$stack"; then
            echo "Deleting CloudFormation stack: $stack"
            aws cloudformation delete-stack \
                --stack-name "$stack" \
                --region "$AWS_REGION" 2>/dev/null || true

            echo "Waiting for stack $stack to be deleted..."
            aws cloudformation wait stack-delete-complete \
                --stack-name "$stack" \
                --region "$AWS_REGION" 2>/dev/null || true
        fi
    done

    # Delete any remaining stacks not in the predefined order
    for stack in $CF_STACKS; do
        if ! echo "$STACK_ORDER" | grep -q "$stack"; then
            echo "Deleting CloudFormation stack: $stack"
            aws cloudformation delete-stack \
                --stack-name "$stack" \
                --region "$AWS_REGION" 2>/dev/null || true

            echo "Waiting for stack $stack to be deleted..."
            aws cloudformation wait stack-delete-complete \
                --stack-name "$stack" \
                --region "$AWS_REGION" 2>/dev/null || true
        fi
    done
else
    echo "No CloudFormation stacks found, skipping..."
fi

echo -e "${GREEN}✓ CloudFormation stacks deleted${NC}"
echo ""

################################################################################
# Cleanup Complete
################################################################################
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}         CLEANUP COMPLETED SUCCESSFULLY                        ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo "All CareFlowAI AWS resources have been deleted."
echo ""
echo -e "${YELLOW}Please verify in the AWS Console that all resources are gone:${NC}"
echo "  1. CloudFormation: https://console.aws.amazon.com/cloudformation"
echo "  2. EC2 Instances: https://console.aws.amazon.com/ec2/v2/home#Instances"
echo "  3. CloudFront: https://console.aws.amazon.com/cloudfront"
echo "  4. S3: https://console.aws.amazon.com/s3"
echo "  5. VPC: https://console.aws.amazon.com/vpc"
echo "  6. Load Balancers: https://console.aws.amazon.com/ec2/v2/home#LoadBalancers"
echo "  7. IAM: https://console.aws.amazon.com/iam"
echo ""
echo -e "${YELLOW}Note: CloudFront distributions may take 10-20 minutes to fully delete.${NC}"
echo ""
