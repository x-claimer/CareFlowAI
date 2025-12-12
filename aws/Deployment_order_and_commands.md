# CareFlowAI Deployment Order and Commands

Complete step-by-step deployment guide with all commands and proper execution order.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Deployment Options](#deployment-options)
3. [Simple Deployment](#simple-deployment-development)
4. [Production Deployment](#production-deployment-with-api-gateway--alb)
5. [Starting Stopped Resources](#starting-stopped-resources)
6. [Stopping Resources to Save Costs](#stopping-resources-to-save-costs)
7. [Verification](#verification)
8. [Post-Deployment](#post-deployment)
9. [Updates](#updates)
10. [Cleanup](#cleanup)
11. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Tools

```bash
# Check AWS CLI
aws --version
# Should show: aws-cli/2.x.x or higher

# Check Python
python3 --version
# Should show: Python 3.10 or higher

# Check Node.js
node --version
npm --version
# For frontend deployment
```

### AWS Configuration

```bash
# Configure AWS credentials
aws configure

# Verify configuration
aws sts get-caller-identity

# Should show your AWS Account ID
```

### Required Information Checklist

- [ ] AWS Account ID
- [ ] EC2 Key Pair Name (create in AWS Console if needed)
- [ ] MongoDB Atlas connection string
- [ ] Google Gemini API key
- [ ] Email address for CloudWatch alarms

---

## Deployment Options

### Option 1: Simple Deployment
- Single EC2 instance
- No load balancer
- No API Gateway
- Cost: ~$10-15/month
- Best for: Development/Testing

### Option 2: Production Deployment
- Auto Scaling Group
- Application Load Balancer
- API Gateway
- CloudWatch monitoring
- Cost: ~$35-52/month
- Best for: Production/Staging

---

## Simple Deployment (Development)

### Step 1: Deploy Core Infrastructure

```powershell
cd aws\scripts
bash deploy-infrastructure.sh
```

**When prompted:**
```
Enter Key Pair Name: your-key-name
Enter Instance Type (default: t2.micro): [press Enter]
Enter AWS Region (default: us-east-1): [press Enter]
```

**Wait for completion** (~10-15 minutes)

**Save the outputs:**
```
VPC ID: vpc-xxxxx
Security Group ID: sg-xxxxx
Elastic IP: x.x.x.x
S3 Bucket: account-id-careflowai-frontend
CloudFront Domain: xxxxx.cloudfront.net
```

### Step 2: Configure MongoDB Atlas

1. Go to https://cloud.mongodb.com
2. Create M0 (free) cluster
3. Create database user
4. Network Access → Add IP Address → **Add Elastic IP from Step 1**
5. Get connection string

### Step 3: Deploy Backend Application

Edit `deploy-backend.sh`:
```bash
# Update these variables
EC2_IP="YOUR_ELASTIC_IP_FROM_STEP_1"
KEY_FILE="/path/to/your-key.pem"
MONGODB_URL="mongodb+srv://user:pass@cluster.mongodb.net/careflowai"
SECRET_KEY="$(openssl rand -hex 32)"  # Or use a fixed key
```

Deploy:
```powershell
bash deploy-backend.sh
```

**Verify backend:**
```powershell
# Test health endpoint
curl http://YOUR_ELASTIC_IP:8000/health

# Expected response:
# {"status":"healthy","service":"CareFlowAI API","database":"MongoDB"}

# View API documentation
Start-Process "http://YOUR_ELASTIC_IP:8000/docs"
```

### Step 4: Deploy Frontend Application

Edit `deploy-frontend.sh`:
```bash
# Update these variables
S3_BUCKET="YOUR_S3_BUCKET_FROM_STEP_1"
CLOUDFRONT_DISTRIBUTION_ID="YOUR_DIST_ID_FROM_STEP_1"
API_URL="http://YOUR_ELASTIC_IP:8000"
```

Deploy:
```powershell
bash deploy-frontend.sh
```

**Verify frontend:**
```powershell
# Access via CloudFront
Start-Process "https://YOUR_CLOUDFRONT_DOMAIN.cloudfront.net"
```

---

## Production Deployment (with API Gateway & ALB)

### What Gets Deployed Where?

Before starting, here's a quick overview:

| Component | Where It's Deployed | Deployment Step |
|-----------|-------------------|-----------------|
| **MongoDB** | MongoDB Atlas (External Cloud) | Manual prerequisite setup |
| **Backend API** | EC2 instances in ASG | Step 3 (infrastructure) + Step 5 (code) |
| **Frontend** | S3 + CloudFront CDN | Step 1 (S3/CF) + Step 6 (build & upload) |
| **Load Balancer** | AWS ALB | Step 2 |
| **API Gateway** | AWS API Gateway | Step 4 |
| **Monitoring** | CloudWatch | Step 7 (optional) |

---

### Prerequisites: Configure MongoDB Atlas

Before deploying, set up MongoDB Atlas (same as Simple Deployment):

1. Go to https://cloud.mongodb.com
2. Create M0 (free) cluster or paid cluster
3. Create database user with password
4. Network Access → Add IP Address → **Add 0.0.0.0/0** (allow all) or your VPC CIDR
5. Get connection string: `mongodb+srv://user:pass@cluster.mongodb.net/careflowai`

**Note:** You'll need this MongoDB URL during deployment.

### Automated Full Deployment (Recommended)

**Important:** Before running the automated deployment:
1. Set up MongoDB Atlas first (see prerequisites below)
2. Have your MongoDB connection string ready

You can deploy everything in one go using the automated script:

```powershell
cd aws\scripts
bash deploy-production-full.sh
```

**The script will prompt you for:**
- EC2 Key Pair Name
- MongoDB Atlas URL (from prerequisite setup)
- Gemini API Key
- SSH key file path (.pem)
- ASG configuration (min/max/desired instances)
- Optional: CloudWatch monitoring email

**The script will automatically deploy:**
- VPC, Subnets, Security Groups
- S3 + CloudFront (for frontend)
- Application Load Balancer
- Auto Scaling Group with Backend EC2 instances
- API Gateway
- Backend application code (Python FastAPI)
- Frontend application (React/Vue)
- CloudWatch monitoring (optional)

**Saves deployment info to:** `aws/deployment-info.txt`

**If the automated script fails or you prefer manual control**, follow the manual steps below.

---



### Manual Step-by-Step Deployment

### Prerequisites: Configure MongoDB Atlas

Before deploying, set up MongoDB Atlas (same as Simple Deployment):

1. Go to https://cloud.mongodb.com
2. Create M0 (free) cluster or paid cluster
3. Create database user with password
4. Network Access → Add IP Address → **Add 0.0.0.0/0** (allow all) or your VPC CIDR
5. Get connection string: `mongodb+srv://user:pass@cluster.mongodb.net/careflowai`

**Note:** You'll need this MongoDB URL during deployment.

---

### Step 1: Deploy Core Infrastructure

```powershell
cd aws\scripts
bash deploy-infrastructure.sh

# When asked about API Gateway, answer: N
# (We'll deploy it separately after ALB)
```

**Save outputs:**
- VPC ID
- Subnet IDs (both)
- Security Group ID
- Elastic IP
- S3 Bucket
- CloudFront Domain

### Step 2: Deploy Application Load Balancer

```powershell
aws cloudformation create-stack `
  --stack-name CareFlowAI-ALB `
  --template-body file://aws/cloudformation/alb.yaml `
  --parameters `
    ParameterKey=VPCId,ParameterValue=YOUR_VPC_ID `
    ParameterKey=PublicSubnet1,ParameterValue=YOUR_SUBNET1_ID `
    ParameterKey=PublicSubnet2,ParameterValue=YOUR_SUBNET2_ID `
  --region us-east-1

# Wait for stack creation
aws cloudformation wait stack-create-complete `
  --stack-name CareFlowAI-ALB `
  --region us-east-1

# Get ALB DNS
aws cloudformation describe-stacks `
  --stack-name CareFlowAI-ALB `
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' `
  --output text
```

**Save:**
- Load Balancer ARN
- Load Balancer DNS
- Target Group ARN
- Backend Security Group ID

### Step 3: Deploy Auto Scaling Group with Backend EC2 Instances

This step creates the EC2 instances that will run your backend application.

```powershell
# Generate JWT secret
$JWT_SECRET = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})

aws cloudformation create-stack `
  --stack-name CareFlowAI-ASG `
  --template-body file://aws/cloudformation/asg.yaml `
  --parameters `
    ParameterKey=KeyName,ParameterValue=YOUR_KEY_NAME `
    ParameterKey=InstanceType,ParameterValue=t2.micro `
    ParameterKey=VPCId,ParameterValue=YOUR_VPC_ID `
    ParameterKey=PublicSubnet1,ParameterValue=YOUR_SUBNET1_ID `
    ParameterKey=PublicSubnet2,ParameterValue=YOUR_SUBNET2_ID `
    ParameterKey=BackendSecurityGroup,ParameterValue=YOUR_BACKEND_SG_ID `
    ParameterKey=TargetGroupArn,ParameterValue=YOUR_TARGET_GROUP_ARN `
    ParameterKey=MongoDBURL,ParameterValue=YOUR_MONGODB_URL `
    ParameterKey=GeminiAPIKey,ParameterValue=YOUR_GEMINI_KEY `
    ParameterKey=SecretKey,ParameterValue=$JWT_SECRET `
    ParameterKey=MinSize,ParameterValue=1 `
    ParameterKey=MaxSize,ParameterValue=3 `
    ParameterKey=DesiredCapacity,ParameterValue=1 `
  --capabilities CAPABILITY_NAMED_IAM `
  --region us-east-1

# Wait for stack creation (~10 minutes)
aws cloudformation wait stack-create-complete `
  --stack-name CareFlowAI-ASG `
  --region us-east-1
```

**What this does:**
- Creates EC2 instances for backend
- Installs Python, dependencies, and sets up the backend environment
- Configures systemd service for the backend API
- Registers instances with the ALB Target Group

### Step 4: Deploy API Gateway

```powershell
cd aws\scripts
bash deploy-api-gateway.sh
```

**The script will:**
- Validate VPC and ALB exist
- Fetch required parameters automatically
- Create VPC Link
- Deploy API Gateway
- Configure routes and logging

**Save:**
- API Gateway ID
- API Gateway URL

### Step 5: Deploy Backend Application Code to ASG

This step deploys your actual Python FastAPI backend code to the EC2 instances.

```powershell
cd aws\scripts
bash deploy-app.sh

# When prompted:
Path to SSH key (.pem file): C:\path\to\your-key.pem
```

**The script will:**
- Find all healthy instances in ASG
- Package your backend application code (Python FastAPI)
- Upload code to each instance via SSH
- Install/update Python dependencies
- Restart the backend service
- Verify deployment and health checks

**What gets deployed:**
- Backend API code from `backend/` directory
- All Python dependencies
- Database models and migrations
- API routes and services

### Step 6: Deploy Frontend with API Gateway URL

Edit `deploy-frontend.sh`:
```bash
S3_BUCKET="YOUR_S3_BUCKET"
CLOUDFRONT_DISTRIBUTION_ID="YOUR_DIST_ID"
API_URL="https://YOUR_API_GATEWAY_URL"  # Use API Gateway URL
```

Deploy:
```powershell
bash deploy-frontend.sh
```

### Step 7: Deploy CloudWatch Monitoring

```powershell
# Get ALB and Target Group full names
$ALB_ARN = aws elbv2 describe-load-balancers `
  --query 'LoadBalancers[?contains(LoadBalancerName, `CareFlowAI`)].LoadBalancerArn' `
  --output text
$ALB_FULL_NAME = $ALB_ARN.Split(':')[5].Substring($ALB_ARN.Split(':')[5].IndexOf('/') + 1)

$TG_ARN = aws elbv2 describe-target-groups `
  --query 'TargetGroups[?contains(TargetGroupName, `CareFlowAI`)].TargetGroupArn' `
  --output text
$TG_FULL_NAME = $TG_ARN.Split(':')[5]

aws cloudformation create-stack `
  --stack-name CareFlowAI-Monitoring `
  --template-body file://aws/cloudformation/cloudwatch.yaml `
  --parameters `
    ParameterKey=AutoScalingGroupName,ParameterValue=CareFlowAI-Backend-ASG `
    ParameterKey=LoadBalancerFullName,ParameterValue=$ALB_FULL_NAME `
    ParameterKey=TargetGroupFullName,ParameterValue=$TG_FULL_NAME `
    ParameterKey=AlarmEmail,ParameterValue=your@email.com `
  --region us-east-1
```

**Important:** Check email and confirm SNS subscription!

---

## Starting Stopped Resources

If you previously stopped your AWS resources to save costs, you can restart them using the startup script.

### Option 1: Use the Automated Startup Script

```powershell
cd aws
bash startup-aws-resources.sh
```

**The script will:**
- Start stopped EC2 instances (from CloudFormation stack or by CareFlowAI tag)
- Verify backend service is responding
- Display resource summary with URLs and health endpoints

**If the script fails**, proceed to Option 2 below to run each step manually.

### Option 2: Start Resources Manually (If Script Fails)

#### Start EC2 Instances

```powershell
# List all stopped EC2 instances
aws ec2 describe-instances `
  --filters "Name=instance-state-name,Values=stopped" "Name=tag:Name,Values=*CareFlowAI*" `
  --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0]]' `
  --output table

# Start specific instance
aws ec2 start-instances --instance-ids YOUR_INSTANCE_ID

# Wait for instance to be running
aws ec2 wait instance-running --instance-ids YOUR_INSTANCE_ID

# Get the public IP
aws ec2 describe-instances `
  --instance-ids YOUR_INSTANCE_ID `
  --query 'Reservations[0].Instances[0].PublicIpAddress' `
  --output text
```

#### Scale Up Auto Scaling Group (if using ASG)

```powershell
# Update ASG desired capacity
aws autoscaling set-desired-capacity `
  --auto-scaling-group-name CareFlowAI-Backend-ASG `
  --desired-capacity 1

# Wait a few minutes for instances to start
Start-Sleep -Seconds 60

# Check instance status
aws autoscaling describe-auto-scaling-groups `
  --auto-scaling-group-names CareFlowAI-Backend-ASG `
  --query 'AutoScalingGroups[0].Instances[*].[InstanceId,LifecycleState]' `
  --output table
```

#### Verify Services

```powershell
# Test backend health endpoint
curl http://YOUR_EC2_IP:8000/health

# Or with ALB
curl http://YOUR_ALB_DNS/health

# Or with API Gateway
curl https://YOUR_API_GATEWAY_URL/health
```

---

## Stopping Resources to Save Costs

When you're not using the application, you can stop resources to reduce AWS costs.

### Stop EC2 Instances

```powershell
# Stop specific EC2 instance
aws ec2 stop-instances --instance-ids YOUR_INSTANCE_ID

# Wait for instance to stop
aws ec2 wait instance-stopped --instance-ids YOUR_INSTANCE_ID

# Or stop all CareFlowAI instances
$instances = aws ec2 describe-instances `
  --filters "Name=tag:Name,Values=*CareFlowAI*" "Name=instance-state-name,Values=running" `
  --query 'Reservations[*].Instances[*].InstanceId' `
  --output text

if ($instances) {
    aws ec2 stop-instances --instance-ids $instances
    Write-Host "Stopped instances: $instances"
}
```

### Scale Down Auto Scaling Group

```powershell
# Set ASG desired capacity to 0
aws autoscaling set-desired-capacity `
  --auto-scaling-group-name CareFlowAI-Backend-ASG `
  --desired-capacity 0

# Verify scaling
aws autoscaling describe-auto-scaling-groups `
  --auto-scaling-group-names CareFlowAI-Backend-ASG `
  --query 'AutoScalingGroups[0].[DesiredCapacity,MinSize,MaxSize]' `
  --output table
```

**Note:**
- S3 and CloudFront don't need to be stopped - they only charge for usage and storage.
- MongoDB Atlas (if using) can be paused from the MongoDB Atlas dashboard.

**To restart resources later**, see [Starting Stopped Resources](#starting-stopped-resources) section above.

---

## Verification

### Check All Resources

```powershell
cd aws
bash check-resources.sh
```

**Expected output:**
```
[1/4] CloudFormation Stacks:
  ✓ CareFlowAI-VPC
  ✓ CareFlowAI-SecurityGroups
  ✓ CareFlowAI-Backend (or CareFlowAI-ASG)
  ✓ CareFlowAI-Frontend
  ✓ CareFlowAI-ALB (if deployed)
  ✓ CareFlowAI-APIGateway (if deployed)

[2/4] EC2 Instances:
  ✓ i-xxxxx (Running)

[3/4] API Gateway:
  ✓ CareFlowAI-API

[4/4] S3 Buckets & CloudFront:
  ✓ S3 bucket with files
  ✓ CloudFront distribution
```

### Test Backend Health

```bash
# Simple deployment
curl http://YOUR_ELASTIC_IP:8000/health

# With ALB
curl http://YOUR_ALB_DNS/health

# With API Gateway
curl https://YOUR_API_GATEWAY_URL/health
```

### Test API Endpoints

```powershell
# Get API documentation
curl http://YOUR_ENDPOINT/docs

# Test authentication (should return 401)
curl http://YOUR_ENDPOINT/api/users

# Test with auth
curl -X POST http://YOUR_ENDPOINT/api/auth/login `
  -H "Content-Type: application/json" `
  -d '{"email":"admin@careflowai.com","password":"admin123"}'
```

### Test Frontend

```powershell
# Open in browser
Start-Process "https://YOUR_CLOUDFRONT_DOMAIN.cloudfront.net"

# Check console for errors (F12)
# Verify API calls are successful
```

---

## Post-Deployment

### Configure DNS (Optional)

```powershell
# Create Route 53 hosted zone
aws route53 create-hosted-zone `
  --name careflowai.com `
  --caller-reference (Get-Date).ToFileTime()

# Create A record for API
$apiRecordJson = @'
{
  "Changes": [{
    "Action": "CREATE",
    "ResourceRecordSet": {
      "Name": "api.careflowai.com",
      "Type": "A",
      "AliasTarget": {
        "HostedZoneId": "YOUR_ALB_HOSTED_ZONE_ID",
        "DNSName": "YOUR_ALB_DNS",
        "EvaluateTargetHealth": true
      }
    }
  }]
}
'@
aws route53 change-resource-record-sets `
  --hosted-zone-id YOUR_ZONE_ID `
  --change-batch $apiRecordJson

# Create A record for frontend
$frontendRecordJson = @'
{
  "Changes": [{
    "Action": "CREATE",
    "ResourceRecordSet": {
      "Name": "www.careflowai.com",
      "Type": "A",
      "AliasTarget": {
        "HostedZoneId": "YOUR_CLOUDFRONT_HOSTED_ZONE_ID",
        "DNSName": "YOUR_CLOUDFRONT_DOMAIN",
        "EvaluateTargetHealth": false
      }
    }
  }]
}
'@
aws route53 change-resource-record-sets `
  --hosted-zone-id YOUR_ZONE_ID `
  --change-batch $frontendRecordJson
```

### Enable HTTPS (Optional)

```powershell
# Request ACM certificate
aws acm request-certificate `
  --domain-name careflowai.com `
  --subject-alternative-names '*.careflowai.com' `
  --validation-method DNS `
  --region us-east-1

# Add certificate to ALB
aws elbv2 create-listener `
  --load-balancer-arn YOUR_ALB_ARN `
  --protocol HTTPS `
  --port 443 `
  --certificates CertificateArn=YOUR_CERT_ARN `
  --default-actions Type=forward,TargetGroupArn=YOUR_TG_ARN
```

### Set Up Monitoring

```powershell
# View CloudWatch dashboard
Start-Process "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=CareFlowAI-Dashboard"

# View logs
aws logs tail /careflowai/backend --follow

# Check alarms
aws cloudwatch describe-alarms `
  --alarm-name-prefix CareFlowAI
```

---

## Updates

### Update Backend Code

```bash
# SSH into instance
ssh -i your-key.pem ubuntu@YOUR_EC2_IP

# Update code
cd /opt/careflowai
git pull origin main

# Update dependencies
cd backend
source venv/bin/activate
pip install -r requirements.txt

# Restart service
sudo systemctl restart careflowai-backend

# Check status
sudo systemctl status careflowai-backend
```

### Update Frontend Code

```powershell
cd aws\scripts
bash deploy-frontend.sh

# Or manually:
cd frontend
npm run build
aws s3 sync dist/ s3://YOUR_BUCKET/ --delete
aws cloudfront create-invalidation `
  --distribution-id YOUR_DIST_ID `
  --paths "/*"
```

### Update Infrastructure

```powershell
# Update CloudFormation stack
aws cloudformation update-stack `
  --stack-name CareFlowAI-ASG `
  --template-body file://aws/cloudformation/asg.yaml `
  --parameters `
    ParameterKey=MinSize,ParameterValue=2 `
    ParameterKey=MaxSize,ParameterValue=5 `
  --capabilities CAPABILITY_NAMED_IAM

# Wait for update
aws cloudformation wait stack-update-complete `
  --stack-name CareFlowAI-ASG
```

---

## Cleanup

### Delete All Resources

```powershell
cd aws
bash cleanup-aws-resources.sh

# Confirm deletion when prompted
```

### Manual Cleanup (if script fails)

```powershell
# Delete stacks in reverse order
aws cloudformation delete-stack --stack-name CareFlowAI-Monitoring
aws cloudformation delete-stack --stack-name CareFlowAI-APIGateway
aws cloudformation delete-stack --stack-name CareFlowAI-ASG
aws cloudformation delete-stack --stack-name CareFlowAI-ALB
aws cloudformation delete-stack --stack-name CareFlowAI-Backend
aws cloudformation delete-stack --stack-name CareFlowAI-Frontend
aws cloudformation delete-stack --stack-name CareFlowAI-SecurityGroups
aws cloudformation delete-stack --stack-name CareFlowAI-VPC

# Empty and delete S3 bucket
aws s3 rm s3://YOUR_BUCKET --recursive
aws s3 rb s3://YOUR_BUCKET
```

---

## Troubleshooting

### Stack Creation Failed

```powershell
# Check stack events
aws cloudformation describe-stack-events `
  --stack-name STACK_NAME `
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`]'

# Delete and retry
aws cloudformation delete-stack --stack-name STACK_NAME
aws cloudformation wait stack-delete-complete --stack-name STACK_NAME
# Then retry creation
```

### Backend Not Responding

```bash
# Check service status
ssh -i your-key.pem ubuntu@YOUR_EC2_IP
sudo systemctl status careflowai-backend

# Check logs
sudo journalctl -u careflowai-backend -n 100 --no-pager

# Check if port is listening
sudo netstat -tlnp | grep 8000

# Restart service
sudo systemctl restart careflowai-backend
```

### API Gateway 504 Timeout

```powershell
# Check VPC Link status
aws apigatewayv2 get-vpc-links `
  --query 'Items[?Name==`CareFlowAI-VPCLink`]'

# Should show: VpcLinkStatus: AVAILABLE

# Check ALB target health
aws elbv2 describe-target-health `
  --target-group-arn YOUR_TG_ARN

# Should show: State: healthy
```

### Frontend Shows Blank Page

```powershell
# Check browser console (F12)
# Look for CORS errors or 404s

# Test API directly
curl http://YOUR_API_ENDPOINT/health

# Verify API_URL in frontend
cd frontend
Get-Content .env.production

# Rebuild and redeploy
npm run build
aws s3 sync dist/ s3://YOUR_BUCKET/ --delete
aws cloudfront create-invalidation --distribution-id YOUR_DIST_ID --paths "/*"
```

### Database Connection Error

```powershell
# Test from EC2 (run from PowerShell on Windows, then SSH)
ssh -i your-key.pem ubuntu@YOUR_EC2_IP

# Once connected via SSH, run this Python code:
python3 -c "from pymongo import MongoClient; import sys; client = MongoClient('YOUR_MONGODB_URL'); print(client.server_info()); print('Connection successful')"

# Or create a test script:
# python3
# from pymongo import MongoClient
# try:
#     client = MongoClient('YOUR_MONGODB_URL')
#     print(client.server_info())
#     print("✓ Connection successful")
# except Exception as e:
#     print(f"✗ Connection failed: {e}")

# Check MongoDB Atlas:
# 1. Network Access → Verify EC2 IP is whitelisted
# 2. Database Access → Verify user exists
# 3. Connection String → Verify format
```

### High Costs

```powershell
# Check running resources
bash aws/check-resources.sh

# Stop EC2 instances when not in use
aws ec2 stop-instances --instance-ids YOUR_INSTANCE_ID

# Set up budget alerts
$budgetJson = @'
{
  "BudgetName": "Monthly-Budget",
  "BudgetLimit": {"Amount": "50", "Unit": "USD"},
  "TimeUnit": "MONTHLY",
  "BudgetType": "COST"
}
'@
aws budgets create-budget `
  --account-id YOUR_ACCOUNT_ID `
  --budget $budgetJson
```

---

**For detailed architecture information, see [Deployment_architecture.md](./Deployment_architecture.md)**

**For service details and costs, see [Services_used_and_cost_comparison.md](./Services_used_and_cost_comparison.md)**
