#!/bin/bash

###############################################################################
# Nginx Setup Script for CareFlowAI Backend
# Configures Nginx as reverse proxy for FastAPI
###############################################################################

set -e

# Configuration
DOMAIN_OR_IP=""  # Your domain or Elastic IP

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

print_message "$GREEN" "Setting up Nginx reverse proxy..."

# Install Nginx if not installed
if ! command -v nginx &> /dev/null; then
    print_message "$YELLOW" "Installing Nginx..."
    sudo apt-get update
    sudo apt-get install -y nginx
fi

# Create Nginx configuration
print_message "$YELLOW" "Creating Nginx configuration..."
sudo tee /etc/nginx/sites-available/careflowai > /dev/null << EOF
server {
    listen 80;
    server_name ${DOMAIN_OR_IP:-_};

    client_max_body_size 10M;

    # API endpoints
    location /api/ {
        proxy_pass http://localhost:8000/api/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }

    # API docs
    location /docs {
        proxy_pass http://localhost:8000/docs;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    # Health check
    location /health {
        proxy_pass http://localhost:8000/health;
        proxy_set_header Host \$host;
    }

    # Root endpoint
    location / {
        proxy_pass http://localhost:8000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable site
print_message "$YELLOW" "Enabling Nginx site..."
sudo ln -sf /etc/nginx/sites-available/careflowai /etc/nginx/sites-enabled/

# Remove default site
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
print_message "$YELLOW" "Testing Nginx configuration..."
sudo nginx -t

# Restart Nginx
print_message "$YELLOW" "Restarting Nginx..."
sudo systemctl restart nginx
sudo systemctl enable nginx

print_message "$GREEN" "Nginx setup completed!"
print_message "$YELLOW" "Test configuration: curl http://localhost/health"
