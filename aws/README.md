# CareFlowAI AWS Deployment Files

This directory contains all necessary files for deploying CareFlowAI to AWS.

## Directory Structure

```
aws/
├── cloudformation/          # CloudFormation YAML templates
│   ├── vpc.yaml            # VPC and networking
│   ├── security-groups.yaml # Security groups
│   ├── ec2-backend.yaml    # EC2 instance for backend
│   └── s3-cloudfront.yaml  # S3 bucket and CloudFront
│
├── scripts/                 # Deployment scripts
│   ├── deploy-infrastructure.sh  # Deploy all AWS infrastructure
│   ├── deploy-backend.sh         # Deploy FastAPI backend to EC2
│   ├── deploy-frontend.sh        # Deploy React frontend to S3
│   └── setup-nginx.sh            # Configure Nginx on EC2
│
├── systemd/                 # Systemd service files
│   ├── careflowai-backend.service  # Backend service
│   └── careflowai-worker.service   # Celery worker (optional)
│
├── nginx/                   # Nginx configuration
│   └── careflowai.conf     # Nginx reverse proxy config
│
├── .env.example                 # Environment variables template
├── AWS_CLI_COMMANDS.md          # Useful AWS CLI commands
├── startup-aws-resources.sh     # Start all AWS resources
├── cleanup-aws-resources.sh     # Delete all AWS resources
└── README.md                    # This file
```

## Quick Start

### Prerequisites

1. AWS Account with appropriate permissions
2. AWS CLI installed and configured
3. EC2 Key Pair created
4. MongoDB Atlas account (free M0 cluster)

### Step 1: Configure Deployment Scripts

Edit `scripts/deploy-infrastructure.sh`:
```bash
KEY_NAME="your-ec2-key-pair-name"
INSTANCE_TYPE="t2.micro"  # or t3.small, t3.medium
REGION="us-east-1"
```

### Step 2: Deploy Infrastructure

```bash
cd aws/scripts
chmod +x deploy-infrastructure.sh
./deploy-infrastructure.sh
```

This will create:
- VPC with public subnets
- Security groups
- EC2 instance (t2.micro by default)
- Elastic IP
- S3 bucket for frontend
- CloudFront distribution

### Step 3: Setup MongoDB Atlas

1. Create MongoDB Atlas account at https://www.mongodb.com/cloud/atlas
2. Create M0 (free) cluster
3. Create database user
4. Whitelist EC2 Elastic IP
5. Get connection string

### Step 4: Deploy Backend

Edit `scripts/deploy-backend.sh`:
```bash
EC2_IP="your-elastic-ip"
KEY_FILE="path/to/your-key.pem"
MONGODB_URL="your-mongodb-connection-string"
SECRET_KEY="generate-with-openssl-rand-hex-32"
```

Deploy:
```bash
chmod +x deploy-backend.sh
./deploy-backend.sh
```

### Step 5: Setup Nginx (Optional but Recommended)

SSH into EC2:
```bash
ssh -i your-key.pem ubuntu@<elastic-ip>
```

Run setup script:
```bash
# Copy nginx config
sudo cp /opt/careflowai/aws/nginx/careflowai.conf /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/careflowai.conf /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
```

Or use the automated script:
```bash
cd /opt/careflowai/aws/scripts
chmod +x setup-nginx.sh
./setup-nginx.sh
```

### Step 6: Deploy Frontend

Edit `scripts/deploy-frontend.sh`:
```bash
S3_BUCKET="your-s3-bucket-name"
CLOUDFRONT_DISTRIBUTION_ID="your-distribution-id"
API_URL="http://your-elastic-ip"
```

Deploy:
```bash
chmod +x deploy-frontend.sh
./deploy-frontend.sh
```

## Architecture Components

### Backend (EC2)
- **Instance Type:** t2.micro (free tier) / t3.small / t3.medium
- **OS:** Ubuntu 22.04 LTS
- **Storage:** 30 GB EBS
- **Services:** FastAPI, Uvicorn, Nginx

### Frontend (S3 + CloudFront)
- **S3:** Static website hosting
- **CloudFront:** Global CDN with HTTPS
- **Framework:** React with Vite

### Database (MongoDB Atlas)
- **Tier:** M0 (free forever)
- **Storage:** 512 MB
- **Features:** Automatic backups, encryption

### Networking
- **VPC:** Custom VPC with public subnets
- **Security Groups:** Configured for HTTP, HTTPS, SSH
- **Elastic IP:** Static IP address for backend

## CloudFormation Templates

### vpc.yaml
Creates VPC, Internet Gateway, Public Subnets, and Route Tables.

**Outputs:**
- VPC ID
- Public Subnet IDs

### security-groups.yaml
Creates security groups for EC2 backend.

**Parameters:**
- VPC ID

**Outputs:**
- Backend Security Group ID

### ec2-backend.yaml
Creates EC2 instance, IAM role, and Elastic IP.

**Parameters:**
- Instance Type (t2.micro, t3.small, t3.medium)
- Key Pair Name
- VPC ID
- Subnet ID
- Security Group ID

**Outputs:**
- Instance ID
- Elastic IP
- Public DNS Name

### s3-cloudfront.yaml
Creates S3 bucket and CloudFront distribution.

**Outputs:**
- S3 Bucket Name
- S3 Website URL
- CloudFront Distribution ID
- CloudFront Domain Name

## Deployment Scripts

### deploy-infrastructure.sh
Deploys all CloudFormation stacks in correct order:
1. VPC
2. Security Groups
3. EC2 Backend
4. S3 + CloudFront

**Configuration:**
- Set `KEY_NAME` before running
- Set `INSTANCE_TYPE` (default: t2.micro)
- Set `REGION` (default: us-east-1)

### deploy-backend.sh
Deploys FastAPI application to EC2:
1. Clones repository
2. Sets up Python virtual environment
3. Installs dependencies
4. Creates .env file
5. Sets up systemd service
6. Starts backend

**Configuration:**
- EC2_IP: Your Elastic IP
- KEY_FILE: Path to .pem key
- MONGODB_URL: MongoDB Atlas connection string
- SECRET_KEY: JWT secret key

### deploy-frontend.sh
Builds and deploys React frontend to S3:
1. Creates production .env file
2. Installs dependencies
3. Builds production bundle
4. Uploads to S3
5. Invalidates CloudFront cache

**Configuration:**
- S3_BUCKET: Your S3 bucket name
- CLOUDFRONT_DISTRIBUTION_ID: Your CloudFront ID
- API_URL: Backend API URL

### setup-nginx.sh
Configures Nginx as reverse proxy:
1. Installs Nginx
2. Creates configuration
3. Enables site
4. Restarts Nginx

## Systemd Services

### careflowai-backend.service
Runs FastAPI application as system service:
- Auto-starts on boot
- Restarts on failure
- Logs to systemd journal

**Usage:**
```bash
sudo systemctl status careflowai-backend
sudo systemctl restart careflowai-backend
sudo systemctl stop careflowai-backend
sudo journalctl -u careflowai-backend -f
```

### careflowai-worker.service (Optional)
Runs Celery worker for background AI processing:
- Used with self-hosted AI (Architecture 3A)
- Requires Redis

**Usage:**
```bash
sudo systemctl status careflowai-worker
sudo systemctl restart careflowai-worker
sudo journalctl -u careflowai-worker -f
```

## Environment Variables

Copy `.env.example` to `.env` and fill in:

```bash
# MongoDB
MONGODB_URL=mongodb+srv://...
DATABASE_NAME=careflowai

# JWT
SECRET_KEY=your-secret-key
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Uploads
UPLOAD_DIR=/opt/careflowai/backend/uploads
MAX_UPLOAD_SIZE=10485760

# Gemini API (optional)
GEMINI_API_KEY=your-api-key
```

## Updating the Application

### Update Backend
```bash
ssh -i your-key.pem ubuntu@<elastic-ip>
cd /opt/careflowai
git pull origin main
cd backend
source venv/bin/activate
pip install -r requirements.txt
sudo systemctl restart careflowai-backend
```

### Update Frontend
```bash
cd aws/scripts
./deploy-frontend.sh
```

## Monitoring

### Check Backend Status
```bash
# Via systemd
sudo systemctl status careflowai-backend

# Via Nginx
curl http://<elastic-ip>/health

# Via logs
sudo journalctl -u careflowai-backend -f
```

### Check Frontend Status
```bash
# S3 website
curl http://<bucket-name>.s3-website-<region>.amazonaws.com

# CloudFront
curl https://<cloudfront-domain>
```

## Troubleshooting

### Backend not responding
```bash
# Check service status
sudo systemctl status careflowai-backend

# Check logs
sudo journalctl -u careflowai-backend -n 100

# Check if port is listening
sudo netstat -tlnp | grep 8000

# Restart service
sudo systemctl restart careflowai-backend
```

### Frontend not loading
```bash
# Check S3 bucket policy
aws s3api get-bucket-policy --bucket <bucket-name>

# Check CloudFront status
aws cloudfront get-distribution --id <distribution-id>

# Invalidate CloudFront cache
aws cloudfront create-invalidation --distribution-id <id> --paths "/*"
```

### Database connection issues
```bash
# Test MongoDB connection
python3 -c "from pymongo import MongoClient; client = MongoClient('your-connection-string'); print(client.server_info())"

# Check if IP is whitelisted in MongoDB Atlas
# Add EC2 Elastic IP to MongoDB Atlas Network Access
```

## Cost Estimates

### Free Tier (First 12 Months)
- EC2 t2.micro: $0 (750 hours/month)
- EBS 30GB: $0
- S3 + CloudFront: $0 (within limits)
- MongoDB Atlas M0: $0 (forever)
- **Total: $0-1/month**

### After Free Tier
- EC2 t2.micro: $8-10/month
- EBS 30GB: $3/month
- S3 + CloudFront: $1-5/month
- MongoDB Atlas M0: $0
- **Total: $12-20/month**

## Security Best Practices

1. **EC2 Security Group:**
   - Restrict SSH (port 22) to your IP only
   - Allow HTTP (80) and HTTPS (443) from anywhere
   - Remove port 8000 after Nginx setup

2. **Environment Variables:**
   - Never commit .env files to git
   - Use strong SECRET_KEY (generated with openssl rand -hex 32)
   - Rotate secrets regularly

3. **MongoDB Atlas:**
   - Use strong passwords
   - Whitelist only EC2 Elastic IP
   - Enable connection encryption

4. **S3 Bucket:**
   - Allow only public read access
   - Use CloudFront for HTTPS

5. **Regular Updates:**
   ```bash
   sudo apt update && sudo apt upgrade -y
   sudo systemctl restart careflowai-backend
   ```

## Resource Management

### Start All Resources (Automated)

To start all stopped AWS resources with one command:

```bash
bash aws/startup-aws-resources.sh
```

This script will:
- Start DocumentDB cluster instances
- Start EC2 backend instances
- Scale up EKS node groups (if applicable)
- Verify service health
- Display resource summary with URLs and endpoints

### Stop Resources (Cost Savings)

To save costs when not using the application:

```bash
# Stop EC2 instances
INSTANCE_ID=$(aws cloudformation describe-stacks \
    --stack-name CareFlowAI-Backend \
    --query 'Stacks[0].Outputs[?OutputKey==`InstanceId`].OutputValue' \
    --output text)
aws ec2 stop-instances --instance-ids $INSTANCE_ID

# Stop DocumentDB cluster (if using DocumentDB instead of MongoDB Atlas)
aws docdb stop-db-cluster --db-cluster-identifier careflowai-mongodb
```

### Resource Cleanup (Delete Everything)

To delete all AWS resources (automated):

```bash
bash aws/cleanup-aws-resources.sh
```

Or manually delete CloudFormation stacks:

```bash
# Delete CloudFormation stacks (in reverse order)
aws cloudformation delete-stack --stack-name CareFlowAI-Frontend
aws cloudformation delete-stack --stack-name CareFlowAI-Backend
aws cloudformation delete-stack --stack-name CareFlowAI-SecurityGroups
aws cloudformation delete-stack --stack-name CareFlowAI-VPC

# Empty and delete S3 bucket
aws s3 rm s3://<bucket-name> --recursive
aws s3 rb s3://<bucket-name>
```

## Support

For issues or questions:
1. Check AWS_CLI_COMMANDS.md for useful commands
2. Review CloudFormation stack events
3. Check systemd service logs
4. Refer to AWS_ARCHITECTURE_GUIDE.md for architecture details

## Next Steps

1. Setup MongoDB Atlas and get connection string
2. Run infrastructure deployment script
3. Deploy backend application
4. Deploy frontend application
5. Configure custom domain (optional)
6. Setup SSL/TLS certificate (optional)
7. Configure monitoring and alerts (optional)
8. Implement CI/CD pipeline (optional)
