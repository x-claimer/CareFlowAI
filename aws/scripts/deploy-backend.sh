#!/bin/bash

###############################################################################
# CareFlowAI Backend Deployment Script
# Deploys FastAPI backend to EC2 instance
###############################################################################

set -e

# Configuration
EC2_IP=""  # Set your EC2 Elastic IP
KEY_FILE=""  # Path to your .pem key file
REPO_URL="https://github.com/your-username/CareFlowAI.git"  # Your repo URL
MONGODB_URL=""  # Your MongoDB Atlas connection string
SECRET_KEY=""  # Your JWT secret key (generate with: openssl rand -hex 32)

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
if [ -z "$EC2_IP" ] || [ -z "$KEY_FILE" ]; then
    print_message "$RED" "Please set EC2_IP and KEY_FILE in the script"
    exit 1
fi

print_message "$GREEN" "Starting backend deployment to EC2: $EC2_IP"

# Create deployment script
cat > /tmp/deploy_backend.sh << 'EOF'
#!/bin/bash
set -e

# Update system
sudo apt-get update

# Clone or update repository
if [ -d "/opt/careflowai" ]; then
    cd /opt/careflowai
    git pull origin main
else
    cd /opt
    sudo git clone REPO_URL careflowai
    sudo chown -R ubuntu:ubuntu careflowai
    cd careflowai
fi

# Setup backend
cd backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Create .env file
cat > .env << ENVEOF
MONGODB_URL=MONGODB_URL_VALUE
DATABASE_NAME=careflowai
SECRET_KEY=SECRET_KEY_VALUE
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
UPLOAD_DIR=/opt/careflowai/backend/uploads
MAX_UPLOAD_SIZE=10485760
ENVEOF

# Create uploads directory
mkdir -p /opt/careflowai/backend/uploads
chmod 755 /opt/careflowai/backend/uploads

# Create systemd service
sudo tee /etc/systemd/system/careflowai-backend.service > /dev/null << SERVICEEOF
[Unit]
Description=CareFlowAI FastAPI Backend
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/careflowai/backend
Environment="PATH=/opt/careflowai/backend/venv/bin"
ExecStart=/opt/careflowai/backend/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 2
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICEEOF

# Reload systemd and start service
sudo systemctl daemon-reload
sudo systemctl enable careflowai-backend
sudo systemctl restart careflowai-backend

# Check service status
sleep 3
sudo systemctl status careflowai-backend --no-pager

echo "Backend deployment completed!"
EOF

# Replace placeholders
sed -i "s|REPO_URL|$REPO_URL|g" /tmp/deploy_backend.sh
sed -i "s|MONGODB_URL_VALUE|$MONGODB_URL|g" /tmp/deploy_backend.sh
sed -i "s|SECRET_KEY_VALUE|$SECRET_KEY|g" /tmp/deploy_backend.sh

# Copy and execute on EC2
print_message "$YELLOW" "Copying deployment script to EC2..."
scp -i "$KEY_FILE" /tmp/deploy_backend.sh ubuntu@$EC2_IP:/tmp/

print_message "$YELLOW" "Executing deployment script on EC2..."
ssh -i "$KEY_FILE" ubuntu@$EC2_IP 'bash /tmp/deploy_backend.sh'

# Clean up
rm /tmp/deploy_backend.sh

print_message "$GREEN" "Backend deployment completed!"
print_message "$YELLOW" "Test backend: curl http://$EC2_IP:8000/health"
