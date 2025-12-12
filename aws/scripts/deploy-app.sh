#!/bin/bash
set -e

# CareFlowAI Application Deployment Script
# This script deploys the application code to all instances in the Auto Scaling Group

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

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}CareFlowAI Application Deployment${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Configuration with defaults from .env or hardcoded fallbacks
ENVIRONMENT_NAME="${ENVIRONMENT_NAME:-CareFlowAI}"
REGION="${REGION:-us-east-1}"
PROFILE="${AWS_PROFILE:-default}"
ASG_NAME="${ASG_NAME:-${ENVIRONMENT_NAME}-Backend-ASG}"
KEY_FILE=""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed${NC}"
    exit 1
fi

# Get key file path
read -p "Path to SSH key file (.pem): " KEY_FILE
if [ ! -f "$KEY_FILE" ]; then
    echo -e "${RED}Error: Key file not found${NC}"
    exit 1
fi
chmod 400 "$KEY_FILE"

# Get instance IPs from Auto Scaling Group
echo -e "${YELLOW}Fetching instances from Auto Scaling Group...${NC}"
INSTANCE_IDS=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $ASG_NAME \
  --query 'AutoScalingGroups[0].Instances[?HealthStatus==`Healthy`].InstanceId' \
  --output text \
  --region $REGION \
  --profile $PROFILE)

if [ -z "$INSTANCE_IDS" ]; then
    echo -e "${RED}Error: No healthy instances found in ASG${NC}"
    exit 1
fi

INSTANCE_COUNT=$(echo $INSTANCE_IDS | wc -w)
echo -e "${GREEN}✓ Found $INSTANCE_COUNT healthy instance(s)${NC}"
echo ""

# Get public IPs
INSTANCE_IPS=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_IDS \
  --query 'Reservations[].Instances[].PublicIpAddress' \
  --output text \
  --region $REGION \
  --profile $PROFILE)

echo -e "${GREEN}Instance IPs:${NC}"
for IP in $INSTANCE_IPS; do
    echo "  - $IP"
done
echo ""

# Create deployment package
echo -e "${YELLOW}Creating deployment package...${NC}"
cd "$PROJECT_ROOT/backend"

# Create a tarball of the application
tar -czf /tmp/careflowai-app.tar.gz \
  --exclude='venv' \
  --exclude='__pycache__' \
  --exclude='*.pyc' \
  --exclude='.env' \
  --exclude='uploads' \
  app/ requirements.txt

echo -e "${GREEN}✓ Deployment package created${NC}"
echo ""

# Deploy to each instance
DEPLOY_COUNT=0
for IP in $INSTANCE_IPS; do
    echo -e "${YELLOW}Deploying to instance: $IP${NC}"

    # Copy application files
    echo "  Copying files..."
    scp -o StrictHostKeyChecking=no -i "$KEY_FILE" /tmp/careflowai-app.tar.gz ubuntu@$IP:/tmp/

    if [ $? -ne 0 ]; then
        echo -e "${RED}  Error: Failed to copy files to $IP${NC}"
        continue
    fi

    # Extract and setup application
    echo "  Setting up application..."
    ssh -o StrictHostKeyChecking=no -i "$KEY_FILE" ubuntu@$IP << 'ENDSSH'
        set -e

        # Extract application
        cd /opt/careflowai
        tar -xzf /tmp/careflowai-app.tar.gz

        # Install/update dependencies
        source venv/bin/activate
        pip install -r requirements.txt --quiet

        # Restart application service
        sudo systemctl restart careflowai

        # Wait a bit for service to start
        sleep 5

        # Check if service is running
        sudo systemctl status careflowai --no-pager

        # Cleanup
        rm /tmp/careflowai-app.tar.gz

        echo "Application deployed successfully"
ENDSSH

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}  ✓ Deployment successful on $IP${NC}"
        DEPLOY_COUNT=$((DEPLOY_COUNT + 1))
    else
        echo -e "${RED}  Error: Deployment failed on $IP${NC}"
    fi
    echo ""
done

# Cleanup local temp file
rm /tmp/careflowai-app.tar.gz

# Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Summary${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "Successfully deployed to: ${GREEN}$DEPLOY_COUNT${NC} / $INSTANCE_COUNT instances"

if [ $DEPLOY_COUNT -eq $INSTANCE_COUNT ]; then
    echo -e "${GREEN}✓ All instances updated successfully!${NC}"
else
    echo -e "${YELLOW}⚠ Some instances failed to update${NC}"
fi

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Test the API endpoint"
echo "2. Monitor CloudWatch logs"
echo "3. Check the CloudWatch dashboard"
echo ""
