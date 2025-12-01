#!/bin/bash
# Backend Deployment Script for CareFlowAI

set -e

EC2_IP="54.225.66.151"
KEY_FILE="$HOME/.ssh/CareFlowAI-Key-New.pem"
APP_DIR="/opt/careflowai"

echo "Deploying CareFlowAI Backend to EC2..."

# Create tar archive of backend code (excluding unnecessary files)
echo "Creating backend archive..."
tar -czf backend.tar.gz \
    --exclude='venv/*' \
    --exclude='*.pyc' \
    --exclude='__pycache__' \
    --exclude='*.db' \
    --exclude='uploads/*' \
    backend/

# Copy archive to EC2
echo "Copying files to EC2..."
scp -i $KEY_FILE backend.tar.gz ubuntu@$EC2_IP:/tmp/

# Extract and setup on EC2
echo "Setting up backend on EC2..."
ssh -i $KEY_FILE ubuntu@$EC2_IP << 'ENDSSH'
set -e

# Extract files
cd /opt/careflowai
sudo tar -xzf /tmp/backend.tar.gz
sudo chown -R ubuntu:ubuntu /opt/careflowai

# Create uploads directory
mkdir -p backend/uploads

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r backend/requirements.txt

echo "Backend files deployed successfully!"
ENDSSH

# Cleanup
rm backend.tar.gz

echo "Backend deployment complete!"
