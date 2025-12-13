#!/bin/bash
set -e

# CareFlowAI Infrastructure Deployment Script
# This script deploys the complete infrastructure stack with ASG, ALB, and CloudWatch

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}CareFlowAI Infrastructure Deployment${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Configuration
ENVIRONMENT_NAME="CareFlowAI"
REGION="us-east-1"
PROFILE="default"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed${NC}"
    exit 1
fi

# Check AWS credentials
echo -e "${YELLOW}Checking AWS credentials...${NC}"
aws sts get-caller-identity --profile $PROFILE > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: AWS credentials not configured${NC}"
    exit 1
fi
echo -e "${GREEN}✓ AWS credentials valid${NC}"

# Get parameters from user
echo ""
echo -e "${YELLOW}Please provide the following parameters:${NC}"
echo ""

read -p "EC2 Key Pair Name: " KEY_NAME
if [ -z "$KEY_NAME" ]; then
    echo -e "${RED}Error: Key pair name is required${NC}"
    exit 1
fi

read -s -p "MongoDB Connection URL: " MONGODB_URL
echo ""
if [ -z "$MONGODB_URL" ]; then
    echo -e "${RED}Error: MongoDB URL is required${NC}"
    exit 1
fi

read -s -p "Google Gemini API Key: " GEMINI_KEY
echo ""
if [ -z "$GEMINI_KEY" ]; then
    echo -e "${RED}Error: Gemini API Key is required${NC}"
    exit 1
fi

read -s -p "JWT Secret Key (press Enter for auto-generated): " SECRET_KEY
echo ""
if [ -z "$SECRET_KEY" ]; then
    SECRET_KEY=$(openssl rand -base64 32)
    echo -e "${GREEN}✓ Generated random JWT secret key${NC}"
fi

read -p "Alarm Email Address: " ALARM_EMAIL
if [ -z "$ALARM_EMAIL" ]; then
    ALARM_EMAIL="admin@example.com"
    echo -e "${YELLOW}Using default email: $ALARM_EMAIL${NC}"
fi

read -p "Instance Type (t3.small/t3.medium/t3.large) [t3.small]: " INSTANCE_TYPE
INSTANCE_TYPE=${INSTANCE_TYPE:-t3.small}

read -p "Minimum Instances [1]: " MIN_SIZE
MIN_SIZE=${MIN_SIZE:-1}

read -p "Maximum Instances [3]: " MAX_SIZE
MAX_SIZE=${MAX_SIZE:-3}

read -p "Desired Instances [1]: " DESIRED_CAPACITY
DESIRED_CAPACITY=${DESIRED_CAPACITY:-1}

# Upload templates to S3 (required for nested stacks)
BUCKET_NAME="${ENVIRONMENT_NAME,,}-cloudformation-templates-$(date +%s)"
echo ""
echo -e "${YELLOW}Creating S3 bucket for CloudFormation templates...${NC}"

aws s3 mb s3://$BUCKET_NAME --region $REGION --profile $PROFILE
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to create S3 bucket${NC}"
    exit 1
fi
echo -e "${GREEN}✓ S3 bucket created: $BUCKET_NAME${NC}"

# Upload templates
echo -e "${YELLOW}Uploading CloudFormation templates...${NC}"
aws s3 sync ../cloudformation s3://$BUCKET_NAME/ --profile $PROFILE --exclude "master-stack.yaml"
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to upload templates${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Templates uploaded${NC}"

# Update master stack template with S3 URLs
TEMPLATE_BASE_URL="https://${BUCKET_NAME}.s3.${REGION}.amazonaws.com"
sed -i.bak "s|TemplateURL: ./|TemplateURL: ${TEMPLATE_BASE_URL}/|g" ../cloudformation/master-stack.yaml

# Deploy the stack
STACK_NAME="${ENVIRONMENT_NAME}-Infrastructure"
echo ""
echo -e "${YELLOW}Deploying CloudFormation stack: $STACK_NAME${NC}"
echo -e "${YELLOW}This may take 10-15 minutes...${NC}"
echo ""

aws cloudformation create-stack \
  --stack-name $STACK_NAME \
  --template-body file://"../cloudformation/master-stack.yaml" \
  --parameters \
    ParameterKey=EnvironmentName,ParameterValue=$ENVIRONMENT_NAME \
    ParameterKey=InstanceType,ParameterValue=$INSTANCE_TYPE \
    ParameterKey=KeyName,ParameterValue=$KEY_NAME \
    ParameterKey=MongoDBURL,ParameterValue=$MONGODB_URL \
    ParameterKey=GeminiAPIKey,ParameterValue=$GEMINI_KEY \
    ParameterKey=SecretKey,ParameterValue=$SECRET_KEY \
    ParameterKey=AlarmEmail,ParameterValue=$ALARM_EMAIL \
    ParameterKey=MinSize,ParameterValue=$MIN_SIZE \
    ParameterKey=MaxSize,ParameterValue=$MAX_SIZE \
    ParameterKey=DesiredCapacity,ParameterValue=$DESIRED_CAPACITY \
  --capabilities CAPABILITY_NAMED_IAM \
  --region $REGION \
  --profile $PROFILE

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to create stack${NC}"
    # Restore original master-stack.yaml
    mv ../cloudformation/master-stack.yaml.bak ../cloudformation/master-stack.yaml
    exit 1
fi

# Wait for stack creation
echo -e "${YELLOW}Waiting for stack creation to complete...${NC}"
aws cloudformation wait stack-create-complete \
  --stack-name $STACK_NAME \
  --region $REGION \
  --profile $PROFILE

if [ $? -eq 0 ]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ Stack deployed successfully!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""

    # Get outputs
    echo -e "${GREEN}Stack Outputs:${NC}"
    aws cloudformation describe-stacks \
      --stack-name $STACK_NAME \
      --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
      --output table \
      --region $REGION \
      --profile $PROFILE

    # Get ALB DNS
    ALB_DNS=$(aws cloudformation describe-stacks \
      --stack-name $STACK_NAME \
      --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
      --output text \
      --region $REGION \
      --profile $PROFILE)

    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Next Steps:${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "1. API Endpoint: ${YELLOW}http://$ALB_DNS${NC}"
    echo -e "2. Health Check: ${YELLOW}http://$ALB_DNS/health${NC}"
    echo -e "3. API Docs: ${YELLOW}http://$ALB_DNS/docs${NC}"
    echo -e "4. Deploy your application code to the instances"
    echo -e "5. Update frontend VITE_API_URL to: ${YELLOW}http://$ALB_DNS${NC}"
    echo -e "6. Check your email to confirm SNS subscription for alarms"
    echo ""

    # Save configuration
    cat > ../deployment-info.txt <<EOF
Deployment Date: $(date)
Stack Name: $STACK_NAME
Region: $REGION
ALB DNS: $ALB_DNS
API URL: http://$ALB_DNS
Health Check: http://$ALB_DNS/health
API Docs: http://$ALB_DNS/docs
S3 Bucket: $BUCKET_NAME
EOF

    echo -e "${GREEN}Deployment info saved to: ../deployment-info.txt${NC}"

else
    echo -e "${RED}Error: Stack creation failed${NC}"
    echo -e "${YELLOW}Check the CloudFormation console for details${NC}"
    exit 1
fi

# Restore original master-stack.yaml
mv ../cloudformation/master-stack.yaml.bak ../cloudformation/master-stack.yaml

echo ""
echo -e "${GREEN}Deployment complete!${NC}"
