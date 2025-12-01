#!/bin/bash

###############################################################################
# CareFlowAI Frontend Deployment Script
# Builds and deploys React frontend to S3
###############################################################################

set -e

# Configuration
S3_BUCKET="428207183791-careflowai-frontend"  # Your S3 bucket name
CLOUDFRONT_DISTRIBUTION_ID="ELQ36TVX16I3O"  # Your CloudFront distribution ID
API_URL="https://54-225-66-151.nip.io"  # Your backend API URL (HTTPS via nginx)
REGION="us-east-1"
# Override to point to a specific aws binary if needed.
# If not provided, we try to pick a Linux binary even if PATH points to /mnt/c/...
AWS_CLI="${AWS_CLI:-}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_message() {
    COLOR=$1
    MESSAGE=$2
    echo -e "${COLOR}${MESSAGE}${NC}"
}

# Validate inputs
if [ -z "$S3_BUCKET" ] || [ -z "$API_URL" ]; then
    print_message "$RED" "Please set S3_BUCKET and API_URL in the script"
    exit 1
fi

if [ -z "$AWS_CLI" ]; then
    # Prefer a non-WSL Windows path
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

print_message "$GREEN" "Starting frontend deployment..."

# Navigate to frontend directory
cd frontend

# Create production environment file
print_message "$YELLOW" "Creating production environment file..."
cat > .env.production << EOF
VITE_API_URL=$API_URL
EOF

# Install dependencies
print_message "$YELLOW" "Installing dependencies..."
npm install

# Build for production
print_message "$YELLOW" "Building production bundle..."
npm run build

# Upload to S3
print_message "$YELLOW" "Uploading to S3 bucket: $S3_BUCKET..."
"$AWS_CLI" s3 sync dist/ s3://$S3_BUCKET/ --delete --region $REGION

# Invalidate CloudFront cache (if distribution ID is provided)
if [ -n "$CLOUDFRONT_DISTRIBUTION_ID" ]; then
    print_message "$YELLOW" "Invalidating CloudFront cache..."
    "$AWS_CLI" cloudfront create-invalidation \
        --distribution-id $CLOUDFRONT_DISTRIBUTION_ID \
        --paths "/*" \
        --region $REGION

    print_message "$GREEN" "CloudFront cache invalidation initiated"
fi

print_message "$GREEN" "Frontend deployment completed!"
print_message "$YELLOW" "Access your application at:"
echo "S3: http://$S3_BUCKET.s3-website-$REGION.amazonaws.com"
if [ -n "$CLOUDFRONT_DISTRIBUTION_ID" ]; then
    CLOUDFRONT_DOMAIN=$("$AWS_CLI" cloudfront get-distribution \
        --id $CLOUDFRONT_DISTRIBUTION_ID \
        --query 'Distribution.DomainName' \
        --output text)
    echo "CloudFront: https://$CLOUDFRONT_DOMAIN"
fi
