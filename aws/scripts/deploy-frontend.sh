#!/bin/bash

###############################################################################
# CareFlowAI Frontend Deployment Script
# Builds and deploys React frontend to S3
###############################################################################

set -e

# Configuration
S3_BUCKET=""  # Your S3 bucket name
CLOUDFRONT_DISTRIBUTION_ID=""  # Your CloudFront distribution ID
API_URL=""  # Your backend API URL (e.g., http://your-elastic-ip)
REGION="us-east-1"

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
aws s3 sync dist/ s3://$S3_BUCKET/ --delete --region $REGION

# Invalidate CloudFront cache (if distribution ID is provided)
if [ -n "$CLOUDFRONT_DISTRIBUTION_ID" ]; then
    print_message "$YELLOW" "Invalidating CloudFront cache..."
    aws cloudfront create-invalidation \
        --distribution-id $CLOUDFRONT_DISTRIBUTION_ID \
        --paths "/*" \
        --region $REGION

    print_message "$GREEN" "CloudFront cache invalidation initiated"
fi

print_message "$GREEN" "Frontend deployment completed!"
print_message "$YELLOW" "Access your application at:"
echo "S3: http://$S3_BUCKET.s3-website-$REGION.amazonaws.com"
if [ -n "$CLOUDFRONT_DISTRIBUTION_ID" ]; then
    CLOUDFRONT_DOMAIN=$(aws cloudfront get-distribution \
        --id $CLOUDFRONT_DISTRIBUTION_ID \
        --query 'Distribution.DomainName' \
        --output text)
    echo "CloudFront: https://$CLOUDFRONT_DOMAIN"
fi
