#!/bin/bash

################################################################################
# AWS CareFlowAI Resource Status Checker
#
# This script checks the status of all CareFlowAI AWS resources
#
# Usage: bash check-resources.sh
################################################################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="us-east-1"

echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}         AWS CAREFLOWAI RESOURCE STATUS CHECKER               ${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Region: $AWS_REGION${NC}"
echo ""

################################################################################
# 1. Check CloudFormation Stacks
################################################################################
echo -e "${YELLOW}[1/5] CloudFormation Stacks:${NC}"
echo ""

STACKS=$(aws cloudformation list-stacks \
    --region "$AWS_REGION" \
    --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE ROLLBACK_COMPLETE UPDATE_ROLLBACK_COMPLETE \
    --query 'StackSummaries[?contains(StackName, `CareFlow`) || contains(StackName, `careflow`)].{Name:StackName,Status:StackStatus}' \
    --output text 2>/dev/null)

if [ -n "$STACKS" ]; then
    echo -e "${GREEN}CloudFormation stacks found:${NC}"
    aws cloudformation list-stacks \
        --region "$AWS_REGION" \
        --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE ROLLBACK_COMPLETE UPDATE_ROLLBACK_COMPLETE \
        --query 'StackSummaries[?contains(StackName, `CareFlow`) || contains(StackName, `careflow`)].[StackName,StackStatus,CreationTime]' \
        --output table
else
    echo -e "${RED}✗ No CloudFormation stacks found${NC}"
fi

echo ""

################################################################################
# 2. Check EC2 Instances
################################################################################
echo -e "${YELLOW}[2/5] EC2 Instances:${NC}"
echo ""

INSTANCES=$(aws ec2 describe-instances \
    --region "$AWS_REGION" \
    --query 'Reservations[*].Instances[?State.Name!=`terminated`]' \
    --output json 2>/dev/null)

INSTANCE_COUNT=$(echo "$INSTANCES" | grep -c "InstanceId" 2>/dev/null || echo "0")
INSTANCE_COUNT=$(echo "$INSTANCE_COUNT" | tr -d '\n\r ' )

if [ "$INSTANCE_COUNT" -gt 0 ]; then
    echo -e "${GREEN}EC2 instances found:${NC}"
    aws ec2 describe-instances \
        --region "$AWS_REGION" \
        --query 'Reservations[*].Instances[?State.Name!=`terminated`].[InstanceId,State.Name,InstanceType,PublicIpAddress,PrivateIpAddress,Tags[?Key==`Name`].Value|[0]]' \
        --output table

    echo ""

    # Count by state
    RUNNING=$(aws ec2 describe-instances \
        --region "$AWS_REGION" \
        --filters "Name=instance-state-name,Values=running" \
        --query 'length(Reservations[*].Instances[*])' \
        --output text 2>/dev/null || echo "0")
    RUNNING=$(echo "$RUNNING" | tr -d '\n\r ' )

    STOPPED=$(aws ec2 describe-instances \
        --region "$AWS_REGION" \
        --filters "Name=instance-state-name,Values=stopped" \
        --query 'length(Reservations[*].Instances[*])' \
        --output text 2>/dev/null || echo "0")
    STOPPED=$(echo "$STOPPED" | tr -d '\n\r ' )

    echo -e "${BLUE}Summary:${NC}"
    echo -e "  ${GREEN}Running: $RUNNING${NC}"
    echo -e "  ${RED}Stopped: $STOPPED${NC}"
else
    echo -e "${RED}✗ No EC2 instances found${NC}"
    echo -e "${YELLOW}  → You need to deploy infrastructure first${NC}"
fi

echo ""

################################################################################
# 3. Check DocumentDB Clusters
################################################################################
echo -e "${YELLOW}[3/5] DocumentDB Clusters:${NC}"
echo ""

DOCDB=$(aws docdb describe-db-clusters \
    --region "$AWS_REGION" \
    --query 'DBClusters[*].[DBClusterIdentifier,Status,Endpoint,Port]' \
    --output table 2>/dev/null)

if [ -n "$DOCDB" ] && [ "$DOCDB" != "" ]; then
    echo -e "${GREEN}DocumentDB clusters found:${NC}"
    echo "$DOCDB"
else
    echo -e "${YELLOW}⚠ No DocumentDB clusters found (you might be using MongoDB Atlas)${NC}"
fi

echo ""

################################################################################
# 4. Check EKS Clusters
################################################################################
echo -e "${YELLOW}[4/5] EKS Clusters:${NC}"
echo ""

EKS_CLUSTERS=$(aws eks list-clusters \
    --region "$AWS_REGION" \
    --query 'clusters[]' \
    --output text 2>/dev/null)

if [ -n "$EKS_CLUSTERS" ]; then
    echo -e "${GREEN}EKS clusters found:${NC}"
    for cluster in $EKS_CLUSTERS; do
        echo ""
        echo -e "${CYAN}Cluster: $cluster${NC}"
        aws eks describe-cluster \
            --name "$cluster" \
            --region "$AWS_REGION" \
            --query 'cluster.{Status:status,Version:version,Endpoint:endpoint}' \
            --output table

        # Check node groups
        NODE_GROUPS=$(aws eks list-nodegroups \
            --cluster-name "$cluster" \
            --region "$AWS_REGION" \
            --query 'nodegroups[]' \
            --output text)

        if [ -n "$NODE_GROUPS" ]; then
            echo -e "${CYAN}Node Groups:${NC}"
            for ng in $NODE_GROUPS; do
                aws eks describe-nodegroup \
                    --cluster-name "$cluster" \
                    --nodegroup-name "$ng" \
                    --region "$AWS_REGION" \
                    --query 'nodegroup.{Name:nodegroupName,Status:status,DesiredSize:scalingConfig.desiredSize,MinSize:scalingConfig.minSize,MaxSize:scalingConfig.maxSize}' \
                    --output table
            done
        fi
    done
else
    echo -e "${YELLOW}⚠ No EKS clusters found${NC}"
fi

echo ""

################################################################################
# 5. Check S3 Buckets and CloudFront
################################################################################
echo -e "${YELLOW}[5/5] S3 Buckets & CloudFront:${NC}"
echo ""

# Check S3 buckets with CareFlow in name
S3_BUCKETS=$(aws s3 ls 2>/dev/null | grep -i careflow | awk '{print $3}')

if [ -n "$S3_BUCKETS" ]; then
    echo -e "${GREEN}S3 buckets found:${NC}"
    for bucket in $S3_BUCKETS; do
        SIZE=$(aws s3 ls s3://$bucket --recursive --summarize 2>/dev/null | grep "Total Size" | awk '{print $3}')
        echo -e "  ${CYAN}$bucket${NC} - Size: ${SIZE:-0} bytes"
    done
else
    echo -e "${YELLOW}⚠ No S3 buckets found with 'careflow' in name${NC}"
fi

echo ""

# Check CloudFront distributions
CF_DISTROS=$(aws cloudfront list-distributions \
    --query 'DistributionList.Items[*].[Id,DomainName,Status,Enabled]' \
    --output text 2>/dev/null)

if [ -n "$CF_DISTROS" ]; then
    echo -e "${GREEN}CloudFront distributions found:${NC}"
    aws cloudfront list-distributions \
        --query 'DistributionList.Items[*].[Id,DomainName,Status,Enabled]' \
        --output table
else
    echo -e "${YELLOW}⚠ No CloudFront distributions found${NC}"
fi

echo ""

################################################################################
# Summary
################################################################################
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}         RESOURCE CHECK COMPLETE                              ${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Provide recommendations
INSTANCE_COUNT=${INSTANCE_COUNT:-0}
RUNNING=${RUNNING:-0}
STOPPED=${STOPPED:-0}

if [ "$INSTANCE_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}⚠ No resources found. You need to deploy infrastructure first.${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "  1. Review: aws/README.md"
    echo "  2. Deploy: bash aws/scripts/deploy-infrastructure.sh"
    echo "  3. Or follow: AWS_DEPLOYMENT_GUIDE.md"
elif [ "$RUNNING" -eq 0 ] && [ "$STOPPED" -gt 0 ]; then
    echo -e "${YELLOW}⚠ All instances are stopped.${NC}"
    echo ""
    echo -e "${BLUE}To start resources:${NC}"
    echo "  bash aws/startup-aws-resources.sh"
elif [ "$RUNNING" -gt 0 ]; then
    echo -e "${GREEN}✓ Resources are running!${NC}"
    echo ""
    echo -e "${BLUE}Access your application:${NC}"

    # Get the first running instance IP
    PUBLIC_IP=$(aws ec2 describe-instances \
        --region "$AWS_REGION" \
        --filters "Name=instance-state-name,Values=running" \
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text 2>/dev/null)

    if [ -n "$PUBLIC_IP" ] && [ "$PUBLIC_IP" != "None" ]; then
        echo "  Backend API: http://$PUBLIC_IP:8000"
        echo "  API Docs: http://$PUBLIC_IP:8000/docs"
        echo "  Health Check: http://$PUBLIC_IP:8000/health"
    fi
fi

echo ""
