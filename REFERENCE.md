# CareFlowAI - Quick Reference & Commands

**All commands and troubleshooting in one place.**

---

## 📖 Table of Contents

1. [Status Checks](#status-checks)
2. [Start/Stop Resources](#startstop-resources)
3. [EC2 Commands](#ec2-commands)
4. [S3 & CloudFront Commands](#s3--cloudfront-commands)
5. [Database Commands](#database-commands)
6. [Logs & Monitoring](#logs--monitoring)
7. [Update & Deploy](#update--deploy)
8. [Troubleshooting Guide](#troubleshooting-guide)
9. [Cost Management](#cost-management)

---

## Status Checks

### Check All Resources

```bash
bash aws/check-resources.sh
```

Shows:
- CloudFormation stacks
- EC2 instances (running/stopped)
- DocumentDB clusters
- EKS clusters
- S3 buckets & CloudFront

### Check EC2 Instances

**All instances:**
```bash
aws ec2 describe-instances --region us-east-1 \
    --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress,Tags[?Key==`Name`].Value|[0]]' \
    --output table
```

**Only running:**
```bash
aws ec2 describe-instances --region us-east-1 \
    --filters "Name=instance-state-name,Values=running" \
    --query 'Reservations[*].Instances[*].[InstanceId,PublicIpAddress]' \
    --output table
```

**Only stopped:**
```bash
aws ec2 describe-instances --region us-east-1 \
    --filters "Name=instance-state-name,Values=stopped" \
    --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0]]' \
    --output table
```

**Count by state:**
```bash
# Running
aws ec2 describe-instances --region us-east-1 \
    --filters "Name=instance-state-name,Values=running" \
    --query 'length(Reservations[*].Instances[*])' \
    --output text

# Stopped
aws ec2 describe-instances --region us-east-1 \
    --filters "Name=instance-state-name,Values=stopped" \
    --query 'length(Reservations[*].Instances[*])' \
    --output text
```

### Check CloudFormation Stacks

```bash
aws cloudformation list-stacks --region us-east-1 \
    --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
    --query 'StackSummaries[*].[StackName,StackStatus]' \
    --output table
```

### Check Backend Health

```bash
# Replace with your IP
curl http://YOUR-ELASTIC-IP/health

# Should return:
# {"status":"healthy"}
```

---

## Start/Stop Resources

### Start All Resources

```bash
bash aws/startup-aws-resources.sh
```

### Start Specific EC2 Instance

```bash
# Start by instance ID
aws ec2 start-instances --instance-ids i-xxxxx --region us-east-1

# Wait for it to start
aws ec2 wait instance-running --instance-ids i-xxxxx --region us-east-1

# Get public IP
aws ec2 describe-instances --instance-ids i-xxxxx \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text
```

### Stop Specific EC2 Instance

```bash
# Stop instance
aws ec2 stop-instances --instance-ids i-xxxxx --region us-east-1

# Wait for it to stop
aws ec2 wait instance-stopped --instance-ids i-xxxxx --region us-east-1
```

### Get Instance ID from CloudFormation

```bash
INSTANCE_ID=$(aws cloudformation describe-stacks \
    --stack-name CareFlowAI-Backend \
    --region us-east-1 \
    --query 'Stacks[0].Outputs[?OutputKey==`InstanceId`].OutputValue' \
    --output text)

echo $INSTANCE_ID
```

---

## EC2 Commands

### SSH into EC2

```bash
ssh -i "path/to/your-key.pem" ubuntu@YOUR-ELASTIC-IP
```

### Get Public IP

```bash
aws ec2 describe-instances --region us-east-1 \
    --filters "Name=instance-state-name,Values=running" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text
```

### Get Instance Status

```bash
aws ec2 describe-instance-status \
    --instance-ids i-xxxxx \
    --region us-east-1 \
    --output table
```

### Get Console Output (Debug)

```bash
aws ec2 get-console-output \
    --instance-ids i-xxxxx \
    --region us-east-1 \
    --output text
```

### List Key Pairs

```bash
aws ec2 describe-key-pairs \
    --query 'KeyPairs[*].KeyName' \
    --output table
```

### Create AMI Backup

```bash
aws ec2 create-image \
    --instance-id i-xxxxx \
    --name "CareFlowAI-Backup-$(date +%Y%m%d)" \
    --description "Backup of CareFlowAI backend"
```

---

## S3 & CloudFront Commands

### List S3 Buckets

```bash
aws s3 ls
```

### Upload Frontend to S3

```bash
cd frontend
npm run build
aws s3 sync dist/ s3://your-bucket-name/ --delete
```

### Download from S3

```bash
aws s3 sync s3://your-bucket-name/ ./local-directory/
```

### Empty S3 Bucket

```bash
aws s3 rm s3://your-bucket-name/ --recursive
```

### List CloudFront Distributions

```bash
aws cloudfront list-distributions \
    --query 'DistributionList.Items[*].[Id,DomainName,Status]' \
    --output table
```

### Create CloudFront Invalidation

```bash
aws cloudfront create-invalidation \
    --distribution-id E123456789ABCD \
    --paths "/*"
```

### Get CloudFront Distribution Info

```bash
aws cloudfront get-distribution --id E123456789ABCD
```

### Get S3 Bucket from CloudFormation

```bash
BUCKET_NAME=$(aws cloudformation describe-stacks \
    --stack-name CareFlowAI-Frontend \
    --region us-east-1 \
    --query 'Stacks[0].Outputs[?OutputKey==`FrontendBucketName`].OutputValue' \
    --output text)

echo $BUCKET_NAME
```

---

## Database Commands

### Test MongoDB Connection (from EC2)

```bash
ssh -i your-key.pem ubuntu@YOUR-ELASTIC-IP
cd /opt/careflowai/backend
source venv/bin/activate

python3 -c "from pymongo import MongoClient; \
client = MongoClient('YOUR-MONGODB-URL'); \
print(client.server_info())"
```

### Check MongoDB Atlas from Local

```bash
python3 -c "from pymongo import MongoClient; \
client = MongoClient('YOUR-MONGODB-URL'); \
print('Connected:', client.server_info()['version'])"
```

### Initialize Database

```bash
ssh -i your-key.pem ubuntu@YOUR-ELASTIC-IP
cd /opt/careflowai/backend
source venv/bin/activate

python scripts/init_db.py
python scripts/add_admin.py
```

---

## Logs & Monitoring

### View Backend Logs (Real-time)

```bash
ssh -i your-key.pem ubuntu@YOUR-ELASTIC-IP
sudo journalctl -u careflowai-backend -f
```

### View Last 100 Log Lines

```bash
ssh -i your-key.pem ubuntu@YOUR-ELASTIC-IP
sudo journalctl -u careflowai-backend -n 100
```

### View Logs Since Time

```bash
# Since 1 hour ago
sudo journalctl -u careflowai-backend --since "1 hour ago"

# Since today
sudo journalctl -u careflowai-backend --since today

# Since specific time
sudo journalctl -u careflowai-backend --since "2025-01-15 10:00:00"
```

### Check Service Status

```bash
ssh -i your-key.pem ubuntu@YOUR-ELASTIC-IP
sudo systemctl status careflowai-backend
```

### Get EC2 CPU Utilization (Last Hour)

```bash
aws cloudwatch get-metric-statistics \
    --namespace AWS/EC2 \
    --metric-name CPUUtilization \
    --dimensions Name=InstanceId,Value=i-xxxxx \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Average
```

### Check CloudFormation Stack Events

```bash
aws cloudformation describe-stack-events \
    --stack-name CareFlowAI-Backend \
    --max-items 20
```

---

## Update & Deploy

### Restart Backend Service

```bash
ssh -i your-key.pem ubuntu@YOUR-ELASTIC-IP
sudo systemctl restart careflowai-backend
```

### Update Backend Code

```bash
ssh -i your-key.pem ubuntu@YOUR-ELASTIC-IP
cd /opt/careflowai
git pull origin main
cd backend
source venv/bin/activate
pip install -r requirements.txt
sudo systemctl restart careflowai-backend
```

### Update Frontend

```bash
cd frontend
bash aws/scripts/deploy-frontend.sh
```

### Update Nginx Configuration

```bash
ssh -i your-key.pem ubuntu@YOUR-ELASTIC-IP
sudo nano /etc/nginx/sites-available/careflowai
# Make changes
sudo nginx -t
sudo systemctl restart nginx
```

---

## Troubleshooting Guide

### Problem: Can't SSH into EC2

**Check instance state:**
```bash
aws ec2 describe-instances \
    --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' \
    --output table
```

**Start if stopped:**
```bash
aws ec2 start-instances --instance-ids i-xxxxx
aws ec2 wait instance-running --instance-ids i-xxxxx
```

**Check security group:**
```bash
# Get security group ID
SG_ID=$(aws cloudformation describe-stacks \
    --stack-name CareFlowAI-SecurityGroups \
    --query 'Stacks[0].Outputs[?OutputKey==`BackendSecurityGroup`].OutputValue' \
    --output text)

# Check inbound rules
aws ec2 describe-security-groups --group-ids $SG_ID
```

**Fix .pem permissions:**
```bash
# Mac/Linux
chmod 400 your-key.pem

# Windows: Remove all users except yourself from file properties
```

---

### Problem: Backend Not Responding

**Check service:**
```bash
ssh -i your-key.pem ubuntu@YOUR-ELASTIC-IP
sudo systemctl status careflowai-backend
```

**View logs:**
```bash
sudo journalctl -u careflowai-backend -n 100
```

**Check if port is listening:**
```bash
sudo netstat -tlnp | grep 8000
```

**Restart service:**
```bash
sudo systemctl restart careflowai-backend
```

**Check .env file:**
```bash
cat /opt/careflowai/backend/.env
# Verify all variables are set
```

---

### Problem: Can't Connect to MongoDB

**Test connection:**
```bash
ssh -i your-key.pem ubuntu@YOUR-ELASTIC-IP
cd /opt/careflowai/backend
source venv/bin/activate

python3 -c "from pymongo import MongoClient; \
client = MongoClient('YOUR-CONNECTION-STRING'); \
print(client.server_info())"
```

**Check MongoDB Atlas:**
1. Network Access includes EC2 Elastic IP
2. Database user exists and password is correct
3. Cluster is running (M0 never stops)

**Verify connection string:**
```bash
cat /opt/careflowai/backend/.env | grep MONGODB_URL
```

---

### Problem: Frontend Not Loading

**Check S3 bucket:**
```bash
aws s3 ls s3://your-bucket-name/
# Should show index.html and assets/
```

**Check CloudFront status:**
```bash
aws cloudfront get-distribution --id E123456789ABCD \
    --query 'Distribution.Status' \
    --output text
# Should show: Deployed
```

**Invalidate cache:**
```bash
aws cloudfront create-invalidation \
    --distribution-id E123456789ABCD \
    --paths "/*"
```

**Check CloudFront errors:**
```bash
# Go to CloudFront Console → Your distribution → Error pages
```

---

### Problem: Frontend Shows Old Version

**Clear CloudFront cache:**
```bash
aws cloudfront create-invalidation \
    --distribution-id E123456789ABCD \
    --paths "/*"
```

**Wait 2-3 minutes, then clear browser cache:**
- Chrome: Ctrl+Shift+Delete
- Firefox: Ctrl+Shift+Delete
- Safari: Cmd+Option+E

**Force reload:**
- Chrome/Firefox: Ctrl+Shift+R
- Safari: Cmd+Shift+R

---

### Problem: 502 Bad Gateway

**Backend service is down:**
```bash
ssh -i your-key.pem ubuntu@YOUR-ELASTIC-IP
sudo systemctl status careflowai-backend
sudo systemctl restart careflowai-backend
```

**Check nginx:**
```bash
sudo nginx -t
sudo systemctl status nginx
sudo systemctl restart nginx
```

**Check logs:**
```bash
sudo journalctl -u careflowai-backend -n 50
sudo tail -f /var/log/nginx/error.log
```

---

### Problem: Permission Errors

**Fix backend file permissions:**
```bash
ssh -i your-key.pem ubuntu@YOUR-ELASTIC-IP
sudo chown -R ubuntu:ubuntu /opt/careflowai
chmod -R 755 /opt/careflowai/backend
chmod -R 777 /opt/careflowai/backend/uploads
```

**Fix .pem file permissions (local):**
```bash
# Mac/Linux
chmod 400 your-key.pem

# Windows
# Right-click .pem → Properties → Security → Advanced
# Disable inheritance, remove all users except yourself
```

---

### Problem: Out of Disk Space

**Check disk usage:**
```bash
ssh -i your-key.pem ubuntu@YOUR-ELASTIC-IP
df -h
```

**Clean up logs:**
```bash
sudo journalctl --vacuum-time=7d
```

**Clean up old packages:**
```bash
sudo apt-get autoremove
sudo apt-get clean
```

---

## Cost Management

### Get Current Month Cost

```bash
aws ce get-cost-and-usage \
    --time-period Start=$(date -u +%Y-%m-01),End=$(date -u +%Y-%m-%d) \
    --granularity MONTHLY \
    --metrics BlendedCost \
    --group-by Type=SERVICE
```

### Stop Resources to Save Money

```bash
# Stop EC2 instance
INSTANCE_ID=$(aws cloudformation describe-stacks \
    --stack-name CareFlowAI-Backend \
    --query 'Stacks[0].Outputs[?OutputKey==`InstanceId`].OutputValue' \
    --output text)

aws ec2 stop-instances --instance-ids $INSTANCE_ID
```

**Savings:**
- EC2 stopped: No compute charges (only storage ~$3/month)
- S3: Pay only for storage used
- CloudFront: Pay only for actual traffic
- MongoDB Atlas M0: Always FREE

### Monitor Costs

1. Go to [AWS Billing Dashboard](https://console.aws.amazon.com/billing)
2. Enable "Free Tier Usage Alerts"
3. Set up billing alarms

---

## Quick Command Cheatsheet

```bash
# Check status of everything
bash aws/check-resources.sh

# Start all stopped resources
bash aws/startup-aws-resources.sh

# SSH into EC2
ssh -i your-key.pem ubuntu@YOUR-ELASTIC-IP

# View backend logs
sudo journalctl -u careflowai-backend -f

# Restart backend
sudo systemctl restart careflowai-backend

# Update backend code
cd /opt/careflowai && git pull && sudo systemctl restart careflowai-backend

# Redeploy frontend
bash aws/scripts/deploy-frontend.sh

# Stop EC2 to save money
aws ec2 stop-instances --instance-ids i-xxxxx

# Get public IP
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' --output text

# Clear CloudFront cache
aws cloudfront create-invalidation --distribution-id E123456789ABCD --paths "/*"

# Delete everything
bash aws/cleanup-aws-resources.sh
```

---

## Environment Variables Reference

**Backend `.env` file:**
```env
# Database
MONGODB_URL=mongodb+srv://user:pass@cluster.mongodb.net/
DATABASE_NAME=careflowai

# JWT Authentication
SECRET_KEY=your-64-character-secret-key
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# File Uploads
UPLOAD_DIR=/opt/careflowai/backend/uploads
MAX_UPLOAD_SIZE=10485760

# AI Services (Optional)
GEMINI_API_KEY=your-gemini-api-key
```

**Frontend `.env.production` (auto-created):**
```env
VITE_API_URL=http://YOUR-ELASTIC-IP
```

---

## AWS Resource IDs Quick Lookup

```bash
# VPC ID
aws cloudformation describe-stacks \
    --stack-name CareFlowAI-VPC \
    --query 'Stacks[0].Outputs[?OutputKey==`VPC`].OutputValue' \
    --output text

# EC2 Instance ID
aws cloudformation describe-stacks \
    --stack-name CareFlowAI-Backend \
    --query 'Stacks[0].Outputs[?OutputKey==`InstanceId`].OutputValue' \
    --output text

# Elastic IP
aws cloudformation describe-stacks \
    --stack-name CareFlowAI-Backend \
    --query 'Stacks[0].Outputs[?OutputKey==`ElasticIP`].OutputValue' \
    --output text

# S3 Bucket Name
aws cloudformation describe-stacks \
    --stack-name CareFlowAI-Frontend \
    --query 'Stacks[0].Outputs[?OutputKey==`FrontendBucketName`].OutputValue' \
    --output text

# CloudFront Domain
aws cloudformation describe-stacks \
    --stack-name CareFlowAI-Frontend \
    --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontDomainName`].OutputValue' \
    --output text
```

---

## Instance States

- **pending** - Instance is starting
- **running** - Instance is active and accessible
- **stopping** - Instance is shutting down
- **stopped** - Instance is stopped (no compute charges)
- **terminated** - Instance is deleted (cannot restart)

---

## Need More Help?

- **Deployment:** See `DEPLOY.md`
- **Architecture:** See `AWS_ARCHITECTURE_GUIDE.md`
- **Docker/K8s:** See `DOCKER_KUBERNETES_SETUP.md`

---

*Keep this file bookmarked for quick reference!*
