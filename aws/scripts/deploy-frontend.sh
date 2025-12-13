#!/bin/bash

###############################################################################
# CareFlowAI Frontend Deployment Script
# Builds and deploys React frontend to S3
###############################################################################

set -e

# Determine PROJECT_ROOT
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

# Configuration with defaults from .env or hardcoded fallbacks
S3_BUCKET="${S3_BUCKET:-428207183791-careflowai-frontend}"
CLOUDFRONT_DISTRIBUTION_ID="${CLOUDFRONT_DISTRIBUTION_ID:-ELQ36TVX16I3O}"
API_URL="${API_URL:-https://54-225-66-151.nip.io}"
REGION="${REGION:-us-east-1}"
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

print_message "$GREEN" "Starting frontend deployment..."

# Navigate to frontend directory
cd "$PROJECT_ROOT/frontend"

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
