#!/bin/bash

################################################################################
# CareFlowAI Full Production Deployment Script
#
# This script automates the complete production deployment including:
# - Core Infrastructure (VPC, Security Groups, S3, CloudFront)
# - Application Load Balancer
# - Auto Scaling Group
# - API Gateway
# - Application Code
# - Frontend
# - CloudWatch Monitoring (optional)
#
# Usage: bash deploy-production-full.sh
################################################################################

set -e

# Determine PROJECT_ROOT early
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
fi

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}    CareFlowAI Full Production Deployment Script               ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Configuration with defaults from .env or hardcoded fallbacks
AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_CLI="${AWS_CLI:-}"

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
    echo -e "${RED}AWS CLI not found. Please install AWS CLI v2.${NC}"
    if [[ "$(uname -s)" == MINGW* ]] || [[ "$(uname -s)" == MSYS* ]]; then
        echo -e "${YELLOW}Download from: https://awscli.amazonaws.com/AWSCLIV2.msi${NC}"
    else
        echo -e "${YELLOW}Install with:${NC}"
        echo -e "${YELLOW}  curl \"https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip\" -o \"awscliv2.zip\"${NC}"
        echo -e "${YELLOW}  unzip awscliv2.zip${NC}"
        echo -e "${YELLOW}  sudo ./aws/install${NC}"
    fi
    exit 1
fi

echo -e "${GREEN}Using AWS CLI: $AWS_CLI${NC}"
export AWS_CLI

################################################################################
# Helper Functions
################################################################################

# Function to check if stack exists
stack_exists() {
    "$AWS_CLI" cloudformation describe-stacks \
        --stack-name $1 \
        --region "$AWS_REGION" \
        &> /dev/null
}

# Function to get stack status
get_stack_status() {
    "$AWS_CLI" cloudformation describe-stacks \
        --stack-name $1 \
        --region "$AWS_REGION" \
        --query 'Stacks[0].StackStatus' \
        --output text 2>/dev/null
}

################################################################################
# Step 0: Load Configuration from .env
################################################################################
echo -e "${BLUE}[0/8] Loading deployment parameters from .env...${NC}"
echo ""

# Use values from .env or hardcoded fallbacks
KEY_NAME="${KEY_NAME:-CareFlowAI-Key-New}"
INSTANCE_TYPE="${INSTANCE_TYPE:-t2.micro}"
MONGODB_URL="${MONGODB_URL:-}"
GEMINI_API_KEY="${GEMINI_API_KEY:-}"
SSH_KEY_PATH="${SSH_KEY_PATH:-}"
MIN_SIZE="${MIN_SIZE:-1}"
MAX_SIZE="${MAX_SIZE:-3}"
DESIRED_CAPACITY="${DESIRED_CAPACITY:-1}"
DEPLOY_MONITORING="${DEPLOY_CLOUDWATCH_MONITORING:-no}"
ALARM_EMAIL="${ALARM_EMAIL:-maur1301@umd.edu}"

echo -e "${GREEN}Configuration Summary:${NC}"
echo "  AWS Region: $AWS_REGION"
echo "  Key Pair: $KEY_NAME"
echo "  Instance Type: $INSTANCE_TYPE"
echo "  ASG: Min=$MIN_SIZE, Max=$MAX_SIZE, Desired=$DESIRED_CAPACITY"
echo "  MongoDB URL: ${MONGODB_URL:0:30}..."
echo "  Gemini API Key: ${GEMINI_API_KEY:0:10}..."
echo "  SSH Key: $SSH_KEY_PATH"
echo "  CloudWatch Monitoring: $DEPLOY_MONITORING"
echo ""
echo -e "${GREEN}Proceeding with deployment using values from .env file...${NC}"
echo ""

# Generate JWT Secret
JWT_SECRET=$(openssl rand -hex 32)
echo -e "${GREEN}✓ Generated JWT Secret${NC}"
echo ""

################################################################################
# Step 1: Deploy Core Infrastructure
################################################################################
echo -e "${BLUE}[1/8] Deploying Core Infrastructure...${NC}"
echo ""

cd "$SCRIPT_DIR"

# Create temporary expect script to automate deploy-infrastructure.sh
cat > /tmp/deploy-infra-expect.sh << 'EOF'
#!/bin/bash
KEY_NAME=$1
INSTANCE_TYPE=$2

bash deploy-infrastructure.sh <<ANSWERS
$KEY_NAME
$INSTANCE_TYPE
us-east-1
N
ANSWERS
EOF

chmod +x /tmp/deploy-infra-expect.sh
/tmp/deploy-infra-expect.sh "$KEY_NAME" "$INSTANCE_TYPE"

echo -e "${GREEN}✓ Core Infrastructure deployed${NC}"
echo ""

# Extract outputs from CloudFormation stacks
echo "Extracting CloudFormation outputs..."

VPC_ID=$("$AWS_CLI" cloudformation describe-stacks \
    --stack-name CareFlowAI-VPC \
    --region "$AWS_REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`VPC`].OutputValue' \
    --output text)

SUBNET1_ID=$("$AWS_CLI" cloudformation describe-stacks \
    --stack-name CareFlowAI-VPC \
    --region "$AWS_REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`PublicSubnet1`].OutputValue' \
    --output text)

SUBNET2_ID=$("$AWS_CLI" cloudformation describe-stacks \
    --stack-name CareFlowAI-VPC \
    --region "$AWS_REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`PublicSubnet2`].OutputValue' \
    --output text)

SECURITY_GROUP_ID=$("$AWS_CLI" cloudformation describe-stacks \
    --stack-name CareFlowAI-SecurityGroups \
    --region "$AWS_REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`BackendSecurityGroup`].OutputValue' \
    --output text)

S3_BUCKET=$("$AWS_CLI" cloudformation describe-stacks \
    --stack-name CareFlowAI-Frontend \
    --region "$AWS_REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`FrontendBucketName`].OutputValue' \
    --output text)

CLOUDFRONT_DISTRIBUTION_ID=$("$AWS_CLI" cloudformation describe-stacks \
    --stack-name CareFlowAI-Frontend \
    --region "$AWS_REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontDistributionId`].OutputValue' \
    --output text)

CLOUDFRONT_DOMAIN=$("$AWS_CLI" cloudformation describe-stacks \
    --stack-name CareFlowAI-Frontend \
    --region "$AWS_REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontDomainName`].OutputValue' \
    --output text)

echo -e "${GREEN}✓ VPC ID: $VPC_ID${NC}"
echo -e "${GREEN}✓ Subnet 1: $SUBNET1_ID${NC}"
echo -e "${GREEN}✓ Subnet 2: $SUBNET2_ID${NC}"
echo -e "${GREEN}✓ Security Group: $SECURITY_GROUP_ID${NC}"
echo -e "${GREEN}✓ S3 Bucket: $S3_BUCKET${NC}"
echo -e "${GREEN}✓ CloudFront: $CLOUDFRONT_DOMAIN${NC}"
echo ""

################################################################################
# Step 2: Deploy Application Load Balancer
################################################################################
echo -e "${BLUE}[2/8] Deploying Application Load Balancer...${NC}"
echo ""

if stack_exists CareFlowAI-ALB; then
    STACK_STATUS=$(get_stack_status CareFlowAI-ALB)
    echo -e "${YELLOW}ALB stack already exists with status: $STACK_STATUS${NC}"

    if [ "$STACK_STATUS" = "CREATE_COMPLETE" ] || [ "$STACK_STATUS" = "UPDATE_COMPLETE" ]; then
        echo -e "${GREEN}✓ Using existing ALB stack${NC}"
    else
        echo -e "${RED}ALB stack is in $STACK_STATUS state. Please check and fix manually.${NC}"
        exit 1
    fi
else
    "$AWS_CLI" cloudformation create-stack \
        --stack-name CareFlowAI-ALB \
        --template-body file://"$PROJECT_ROOT"/aws/cloudformation/alb.yaml \
        --parameters \
            ParameterKey=VPCId,ParameterValue="$VPC_ID" \
            ParameterKey=PublicSubnet1,ParameterValue="$SUBNET1_ID" \
            ParameterKey=PublicSubnet2,ParameterValue="$SUBNET2_ID" \
        --region "$AWS_REGION"

    echo "Waiting for ALB stack creation (this may take 5-10 minutes)..."
    "$AWS_CLI" cloudformation wait stack-create-complete \
        --stack-name CareFlowAI-ALB \
        --region "$AWS_REGION"

    echo -e "${GREEN}✓ ALB stack created${NC}"
fi

# Extract ALB outputs
ALB_ARN=$("$AWS_CLI" cloudformation describe-stacks \
    --stack-name CareFlowAI-ALB \
    --region "$AWS_REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerArn`].OutputValue' \
    --output text)

ALB_DNS=$("$AWS_CLI" cloudformation describe-stacks \
    --stack-name CareFlowAI-ALB \
    --region "$AWS_REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
    --output text)

TARGET_GROUP_ARN=$("$AWS_CLI" cloudformation describe-stacks \
    --stack-name CareFlowAI-ALB \
    --region "$AWS_REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`BackendTargetGroup`].OutputValue' \
    --output text)

BACKEND_SG_ID=$("$AWS_CLI" cloudformation describe-stacks \
    --stack-name CareFlowAI-ALB \
    --region "$AWS_REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`BackendSecurityGroup`].OutputValue' \
    --output text)

echo -e "${GREEN}✓ ALB deployed${NC}"
echo -e "${GREEN}✓ ALB DNS: $ALB_DNS${NC}"
echo -e "${GREEN}✓ Target Group ARN: $TARGET_GROUP_ARN${NC}"
echo ""

################################################################################
# Step 3: Deploy Auto Scaling Group
################################################################################
echo -e "${BLUE}[3/8] Deploying Auto Scaling Group...${NC}"
echo ""

if stack_exists CareFlowAI-ASG; then
    STACK_STATUS=$(get_stack_status CareFlowAI-ASG)
    echo -e "${YELLOW}ASG stack already exists with status: $STACK_STATUS${NC}"

    if [ "$STACK_STATUS" = "CREATE_COMPLETE" ] || [ "$STACK_STATUS" = "UPDATE_COMPLETE" ]; then
        echo -e "${GREEN}✓ Using existing ASG stack${NC}"
    else
        echo -e "${RED}ASG stack is in $STACK_STATUS state. Please check and fix manually.${NC}"
        exit 1
    fi
else
    "$AWS_CLI" cloudformation create-stack \
        --stack-name CareFlowAI-ASG \
        --template-body file://"$PROJECT_ROOT"/aws/cloudformation/asg.yaml \
        --parameters \
            ParameterKey=KeyName,ParameterValue="$KEY_NAME" \
            ParameterKey=InstanceType,ParameterValue="$INSTANCE_TYPE" \
            ParameterKey=VPCId,ParameterValue="$VPC_ID" \
            ParameterKey=PublicSubnet1,ParameterValue="$SUBNET1_ID" \
            ParameterKey=PublicSubnet2,ParameterValue="$SUBNET2_ID" \
            ParameterKey=BackendSecurityGroup,ParameterValue="$BACKEND_SG_ID" \
            ParameterKey=TargetGroupArn,ParameterValue="$TARGET_GROUP_ARN" \
            ParameterKey=LoadBalancerArn,ParameterValue="$ALB_ARN" \
            ParameterKey=MongoDBURL,ParameterValue="$MONGODB_URL" \
            ParameterKey=GeminiAPIKey,ParameterValue="$GEMINI_API_KEY" \
            ParameterKey=SecretKey,ParameterValue="$JWT_SECRET" \
            ParameterKey=MinSize,ParameterValue="$MIN_SIZE" \
            ParameterKey=MaxSize,ParameterValue="$MAX_SIZE" \
            ParameterKey=DesiredCapacity,ParameterValue="$DESIRED_CAPACITY" \
        --capabilities CAPABILITY_NAMED_IAM \
        --region "$AWS_REGION"

    echo "Waiting for ASG stack creation (this may take 10-15 minutes)..."
    "$AWS_CLI" cloudformation wait stack-create-complete \
        --stack-name CareFlowAI-ASG \
        --region "$AWS_REGION"

    echo -e "${GREEN}✓ ASG stack created${NC}"
fi

echo -e "${GREEN}✓ Auto Scaling Group deployed${NC}"
echo ""

################################################################################
# Step 4: Deploy API Gateway
################################################################################
echo -e "${BLUE}[4/8] Deploying API Gateway...${NC}"
echo ""

cd "$SCRIPT_DIR"
bash deploy-api-gateway.sh

# Extract API Gateway outputs
API_GATEWAY_ID=$("$AWS_CLI" cloudformation describe-stacks \
    --stack-name CareFlowAI-APIGateway \
    --region "$AWS_REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`APIGatewayId`].OutputValue' \
    --output text 2>/dev/null || echo "")

API_GATEWAY_URL=$("$AWS_CLI" cloudformation describe-stacks \
    --stack-name CareFlowAI-APIGateway \
    --region "$AWS_REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`APIGatewayURL`].OutputValue' \
    --output text 2>/dev/null || echo "")

if [ -z "$API_GATEWAY_URL" ]; then
    # Fallback: construct URL from API Gateway ID
    API_GATEWAY_URL="https://${API_GATEWAY_ID}.execute-api.${AWS_REGION}.amazonaws.com"
fi

echo -e "${GREEN}✓ API Gateway deployed${NC}"
echo -e "${GREEN}✓ API Gateway URL: $API_GATEWAY_URL${NC}"
echo ""

################################################################################
# Step 5: Deploy Application Code to ASG Instances
################################################################################
echo -e "${BLUE}[5/8] Deploying application code to ASG instances...${NC}"
echo ""

# Create temporary expect script for deploy-app.sh
cat > /tmp/deploy-app-expect.sh << EOF
#!/bin/bash
SSH_KEY=\$1

bash deploy-app.sh <<ANSWERS
\$SSH_KEY
ANSWERS
EOF

chmod +x /tmp/deploy-app-expect.sh
cd "$SCRIPT_DIR"
/tmp/deploy-app-expect.sh "$SSH_KEY_PATH"

echo -e "${GREEN}✓ Application code deployed to ASG instances${NC}"
echo ""

################################################################################
# Step 6: Deploy Frontend
################################################################################
echo -e "${BLUE}[6/8] Deploying frontend...${NC}"
echo ""

# Update deploy-frontend.sh with correct values
DEPLOY_FRONTEND_SCRIPT="$SCRIPT_DIR/deploy-frontend.sh"

if [ -f "$DEPLOY_FRONTEND_SCRIPT" ]; then
    # Create a temporary version with updated values
    cp "$DEPLOY_FRONTEND_SCRIPT" "$DEPLOY_FRONTEND_SCRIPT.backup"

    # Update the variables in the script
    sed -i "s|^S3_BUCKET=.*|S3_BUCKET=\"$S3_BUCKET\"|g" "$DEPLOY_FRONTEND_SCRIPT"
    sed -i "s|^CLOUDFRONT_DISTRIBUTION_ID=.*|CLOUDFRONT_DISTRIBUTION_ID=\"$CLOUDFRONT_DISTRIBUTION_ID\"|g" "$DEPLOY_FRONTEND_SCRIPT"
    sed -i "s|^API_URL=.*|API_URL=\"$API_GATEWAY_URL\"|g" "$DEPLOY_FRONTEND_SCRIPT"

    bash "$DEPLOY_FRONTEND_SCRIPT"

    # Restore backup
    mv "$DEPLOY_FRONTEND_SCRIPT.backup" "$DEPLOY_FRONTEND_SCRIPT"
else
    echo -e "${YELLOW}⚠ deploy-frontend.sh not found, skipping frontend deployment${NC}"
    echo "You can deploy frontend manually later."
fi

echo -e "${GREEN}✓ Frontend deployed${NC}"
echo ""

################################################################################
# Step 7: Deploy CloudWatch Monitoring (Optional)
################################################################################
if [ "$DEPLOY_MONITORING" = "yes" ]; then
    echo -e "${BLUE}[7/8] Deploying CloudWatch Monitoring...${NC}"
    echo ""

    if stack_exists CareFlowAI-Monitoring; then
        STACK_STATUS=$(get_stack_status CareFlowAI-Monitoring)
        echo -e "${YELLOW}CloudWatch Monitoring stack already exists with status: $STACK_STATUS${NC}"

        if [ "$STACK_STATUS" = "CREATE_COMPLETE" ] || [ "$STACK_STATUS" = "UPDATE_COMPLETE" ]; then
            echo -e "${GREEN}✓ Using existing CloudWatch Monitoring stack${NC}"
        else
            echo -e "${RED}CloudWatch Monitoring stack is in $STACK_STATUS state. Please check and fix manually.${NC}"
            exit 1
        fi
    else
        # Get ALB and Target Group full names
        ALB_FULL_NAME=$(echo "$ALB_ARN" | cut -d':' -f6 | cut -d'/' -f2-)
        TG_FULL_NAME=$(echo "$TARGET_GROUP_ARN" | cut -d':' -f6)

        "$AWS_CLI" cloudformation create-stack \
            --stack-name CareFlowAI-Monitoring \
            --template-body file://"$PROJECT_ROOT"/aws/cloudformation/cloudwatch.yaml \
            --parameters \
                ParameterKey=AutoScalingGroupName,ParameterValue=CareFlowAI-Backend-ASG \
                ParameterKey=LoadBalancerFullName,ParameterValue="$ALB_FULL_NAME" \
                ParameterKey=TargetGroupFullName,ParameterValue="$TG_FULL_NAME" \
                ParameterKey=AlarmEmail,ParameterValue="$ALARM_EMAIL" \
            --region "$AWS_REGION"

        echo "Waiting for CloudWatch stack creation..."
        "$AWS_CLI" cloudformation wait stack-create-complete \
            --stack-name CareFlowAI-Monitoring \
            --region "$AWS_REGION"

        echo -e "${GREEN}✓ CloudWatch Monitoring stack created${NC}"
    fi

    echo -e "${GREEN}✓ CloudWatch Monitoring deployed${NC}"
    echo -e "${YELLOW}⚠ Important: Check your email ($ALARM_EMAIL) and confirm SNS subscription!${NC}"
    echo ""
else
    echo -e "${YELLOW}[7/8] Skipping CloudWatch Monitoring deployment${NC}"
    echo ""
fi

################################################################################
# Step 8: Verification
################################################################################
echo -e "${BLUE}[8/8] Verifying deployment...${NC}"
echo ""

# Wait a bit for services to fully initialize
echo "Waiting 30 seconds for services to initialize..."
sleep 30

# Test backend health endpoint
echo "Testing backend health endpoint..."
HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" "$API_GATEWAY_URL/health" || echo "000")

if [ "$HEALTH_CHECK" = "200" ]; then
    echo -e "${GREEN}✓ Backend service is responding (HTTP 200)${NC}"
else
    echo -e "${YELLOW}⚠ Backend service returned HTTP $HEALTH_CHECK${NC}"
    echo "  It may still be initializing. Check manually later."
fi

echo ""

################################################################################
# Deployment Complete
################################################################################
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}         PRODUCTION DEPLOYMENT COMPLETED                       ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Save deployment information to a file
DEPLOYMENT_INFO_FILE="$PROJECT_ROOT/aws/deployment-info.txt"
cat > "$DEPLOYMENT_INFO_FILE" << EOF
CareFlowAI Production Deployment Information
Deployment Date: $(date)

=== Infrastructure ===
VPC ID: $VPC_ID
Subnet 1: $SUBNET1_ID
Subnet 2: $SUBNET2_ID
Security Group: $SECURITY_GROUP_ID

=== Load Balancer ===
ALB ARN: $ALB_ARN
ALB DNS: $ALB_DNS
Target Group ARN: $TARGET_GROUP_ARN

=== API Gateway ===
API Gateway ID: $API_GATEWAY_ID
API Gateway URL: $API_GATEWAY_URL

=== Frontend ===
S3 Bucket: $S3_BUCKET
CloudFront Distribution ID: $CLOUDFRONT_DISTRIBUTION_ID
CloudFront URL: https://$CLOUDFRONT_DOMAIN

=== Auto Scaling Group ===
ASG Name: CareFlowAI-Backend-ASG
Min Size: $MIN_SIZE
Max Size: $MAX_SIZE
Desired Capacity: $DESIRED_CAPACITY

=== Secrets (KEEP SECURE!) ===
JWT Secret: $JWT_SECRET
MongoDB URL: $MONGODB_URL
Gemini API Key: $GEMINI_API_KEY
EOF

echo -e "${GREEN}Deployment Summary:${NC}"
echo ""
echo -e "${BLUE}Backend API:${NC}"
echo "  ALB DNS: http://$ALB_DNS"
echo "  API Gateway URL: $API_GATEWAY_URL"
echo "  Health Check: $API_GATEWAY_URL/health"
echo "  API Docs: $API_GATEWAY_URL/docs"
echo ""
echo -e "${BLUE}Frontend:${NC}"
echo "  CloudFront URL: https://$CLOUDFRONT_DOMAIN"
echo ""
echo -e "${BLUE}Important Files:${NC}"
echo "  Deployment Info: $DEPLOYMENT_INFO_FILE"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. Test API: curl $API_GATEWAY_URL/health"
echo "  2. Open frontend: https://$CLOUDFRONT_DOMAIN"
echo "  3. Test login with admin credentials"
if [ "$DEPLOY_MONITORING" = "yes" ]; then
echo "  4. Confirm SNS subscription in email: $ALARM_EMAIL"
fi
echo ""
echo -e "${YELLOW}Note: Services may take a few more minutes to fully initialize.${NC}"
echo ""

# Cleanup temporary files
rm -f /tmp/deploy-infra-expect.sh
rm -f /tmp/deploy-app-expect.sh

echo -e "${GREEN}Deployment script completed successfully!${NC}"
