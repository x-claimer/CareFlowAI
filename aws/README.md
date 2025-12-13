# CareFlowAI AWS Deployment

Complete AWS infrastructure and deployment guide for the CareFlowAI healthcare management system. Deploy a production-ready, scalable, and highly available application on AWS.

---

## 📋 Table of Contents

- [Architecture Overview](#-architecture-overview)
- [Directory Structure](#-directory-structure)
- [Prerequisites](#-prerequisites)
- [Deployment Options](#-deployment-options)
- [AWS Services Used](#-aws-services-used)
- [Quick Start](#-quick-start)
- [Management Scripts](#-management-scripts)
- [Common Operations](#-common-operations)
- [Security Features](#-security-features)
- [Monitoring](#-monitoring)
- [Troubleshooting](#-troubleshooting)

---

## 🏗️ Architecture Overview

### Production Architecture

```
Internet
  ↓
CloudFront (CDN) ← S3 (React Frontend)
  ↓
API Gateway (HTTP API)
  ↓
VPC Link
  ↓
Application Load Balancer
  ↓
Auto Scaling Group (1-3 EC2 t2.micro)
  ├── EC2 Instance 1 (FastAPI Backend)
  ├── EC2 Instance 2 (FastAPI Backend)
  └── EC2 Instance 3 (FastAPI Backend)
  ↓
External Services
  ├── MongoDB Atlas (Database)
  └── Google Gemini AI (AI Services)
```

### Key Features

- ✅ **Auto Scaling**: 1-3 t2.micro instances based on CPU/traffic
- ✅ **Load Balancing**: Application Load Balancer with health checks
- ✅ **API Management**: API Gateway with rate limiting and throttling
- ✅ **CDN**: CloudFront for global content distribution
- ✅ **Monitoring**: CloudWatch logs, metrics, and alarms
- ✅ **High Availability**: Multi-AZ deployment
- ✅ **Cost Optimized**: ~$35-52/month (adjustable)

---

## 📁 Directory Structure

```
aws/
├── cloudformation/                  # Infrastructure as Code
│   ├── vpc.yaml                    # VPC and networking (2 AZs)
│   ├── security-groups.yaml        # Security groups for ALB and EC2
│   ├── ec2-backend.yaml            # Single EC2 instance (simple setup)
│   ├── s3-cloudfront.yaml          # S3 bucket and CloudFront distribution
│   ├── alb.yaml                    # Application Load Balancer
│   ├── asg.yaml                    # Auto Scaling Group (production)
│   ├── api-gateway.yaml            # API Gateway with VPC Link
│   └── cloudwatch.yaml             # Monitoring, logs, and alarms
│
├── scripts/                         # Deployment automation
│   ├── deploy-infrastructure.sh    # Deploy core infrastructure (VPC, ALB, ASG)
│   ├── deploy-api-gateway.sh       # Deploy API Gateway
│   ├── deploy-backend.sh           # Deploy backend to EC2
│   ├── deploy-frontend.sh          # Build and deploy frontend to S3
│   └── deploy-app.sh               # Deploy application to ASG instances
│
├── check-resources.sh               # Check status of deployed resources
├── cleanup-aws-resources.sh         # Delete all AWS resources
├── startup-aws-resources.sh         # Start stopped EC2 instances
│
├── README.md                        # This file
├── QuickStart.md                    # 15-minute quick start guide
├── Deployment_architecture.md       # Detailed architecture diagrams
├── Deployment_order_and_commands.md # Step-by-step deployment instructions
└── Services_used_and_cost_comparison.md  # AWS services and cost breakdown
```

---

## 🚀 Quick Links to Documentation

- **[QuickStart.md](./QuickStart.md)** - Get started in 15 minutes with minimal configuration
- **[Deployment_architecture.md](./Deployment_architecture.md)** - Detailed architecture and design decisions
- **[Deployment_order_and_commands.md](./Deployment_order_and_commands.md)** - Complete deployment walkthrough
- **[Services_used_and_cost_comparison.md](./Services_used_and_cost_comparison.md)** - AWS services list and cost analysis

---

## 📋 Prerequisites

### 1. AWS Account Setup
- Active AWS account with administrator access
- Billing alerts configured (recommended)
- Default VPC deleted (optional, for clean setup)

### 2. AWS CLI Installation & Configuration
```bash
# Install AWS CLI v2
# Windows: Download from https://aws.amazon.com/cli/
# macOS: brew install awscli
# Linux: curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Configure credentials
aws configure
# Enter:
#   - AWS Access Key ID
#   - AWS Secret Access Key
#   - Default region (e.g., us-east-1)
#   - Default output format (json)

# Verify installation
aws sts get-caller-identity
```

### 3. EC2 Key Pair
```bash
# Create a new key pair
aws ec2 create-key-pair \
  --key-name CareFlowAI-Key \
  --query 'KeyMaterial' \
  --output text > CareFlowAI-Key.pem

# Set permissions (macOS/Linux)
chmod 400 CareFlowAI-Key.pem

# Windows: Right-click > Properties > Security > Advanced
```

### 4. External Services
- **MongoDB Atlas**: Connection string for database
  - Free tier available at https://www.mongodb.com/cloud/atlas
  - Set up database user and whitelist AWS IP ranges
- **Google Gemini API**: API key for AI services
  - Get key from https://makersuite.google.com/app/apikey

---

## 🎯 Deployment Options

### Option 1: Quick Deploy (Testing/Development)

Deploy single EC2 instance without auto-scaling.

```bash
cd aws/scripts

# Deploy infrastructure
bash deploy-infrastructure.sh

# Deploy backend to EC2
bash deploy-backend.sh

# Deploy frontend to S3/CloudFront
bash deploy-frontend.sh
```

**Time**: ~20 minutes
**Cost**: ~$10-15/month
**Recommended for**: Testing, development, demos

### Option 2: Full Production Deploy

Deploy with auto-scaling, load balancing, and API Gateway.

```bash
cd aws/scripts

# 1. Deploy core infrastructure (VPC, Security Groups, ALB, ASG)
bash deploy-infrastructure.sh

# 2. Deploy API Gateway
bash deploy-api-gateway.sh

# 3. Deploy backend to all ASG instances
bash deploy-app.sh

# 4. Deploy frontend to S3/CloudFront
bash deploy-frontend.sh
```

**Time**: ~30-40 minutes
**Cost**: ~$35-52/month
**Recommended for**: Production, high availability

### Option 3: Manual CloudFormation Deploy

Use AWS Console to deploy CloudFormation templates individually.

1. VPC and Networking: `cloudformation/vpc.yaml`
2. Security Groups: `cloudformation/security-groups.yaml`
3. Application Load Balancer: `cloudformation/alb.yaml`
4. Auto Scaling Group: `cloudformation/asg.yaml`
5. API Gateway: `cloudformation/api-gateway.yaml`
6. S3 and CloudFront: `cloudformation/s3-cloudfront.yaml`
7. CloudWatch: `cloudformation/cloudwatch.yaml`

---

## 💰 AWS Services Used

| Service | Purpose | Monthly Cost (Estimate) |
|---------|---------|-------------------------|
| **EC2 (t2.micro)** | Backend hosting (1-3 instances) | $8.50 - $25.50 |
| **Application Load Balancer** | Load balancing and health checks | $16.20 |
| **API Gateway** | API management and rate limiting | $1.00 - $3.00 |
| **CloudFront** | Global CDN for frontend | $1.00 |
| **S3** | Frontend static file hosting | $0.50 |
| **CloudWatch** | Logs, metrics, and alarms | $3.00 |
| **VPC** | Virtual Private Cloud | $0.00 (free) |
| **NAT Gateway** | Outbound internet for private subnets | $32.40 (optional) |
| **VPC Link** | API Gateway to VPC connection | $0.00 |
| **Auto Scaling** | Automatic instance scaling | $0.00 |
| **Elastic IP** | Static IP for EC2 (single instance) | $0.00 (when attached) |
| **Data Transfer** | Outbound data transfer | ~$1-5 |
| **Total (without NAT)** | | **~$35-52/month** |
| **Total (with NAT)** | | **~$67-84/month** |

### Cost Optimization Tips
- Use t2.micro free tier (12 months for new accounts)
- Stop instances during off-hours for development
- Use CloudFront caching to reduce data transfer
- Monitor usage with Cost Explorer
- Set up billing alarms

---

## ⚙️ Quick Start

For detailed quick start guide, see [QuickStart.md](./QuickStart.md).

### 1. Clone and Navigate
```bash
git clone <repository-url>
cd CareFlowAI/aws
```

### 2. Configure Environment
```bash
# Update scripts with your values
# - EC2 Key Pair name
# - MongoDB connection string
# - Google Gemini API key
# - AWS region
```

### 3. Deploy
```bash
cd scripts
bash deploy-infrastructure.sh
bash deploy-frontend.sh
```

### 4. Access Application
```bash
# Get CloudFront URL
aws cloudfront list-distributions \
  --query 'DistributionList.Items[?Comment==`CareFlowAI Frontend`].DomainName' \
  --output text

# Get ALB URL
aws elbv2 describe-load-balancers \
  --names CareFlowAI-ALB \
  --query 'LoadBalancers[0].DNSName' \
  --output text
```

---

## 🔧 Management Scripts

### Check Resource Status
```bash
bash check-resources.sh
```

Shows status of:
- VPC and subnets
- EC2 instances
- Load balancers
- Auto Scaling Groups
- CloudFront distributions
- S3 buckets

### Start Stopped Resources
```bash
bash startup-aws-resources.sh
```

Starts all stopped EC2 instances.

### Delete All Resources
```bash
bash cleanup-aws-resources.sh
```

**Warning**: This deletes all CareFlowAI resources. Use with caution!

Deletes in order:
1. CloudWatch alarms
2. API Gateway
3. Auto Scaling Group
4. Load Balancer
5. Target Groups
6. EC2 instances
7. CloudFront distributions
8. S3 buckets
9. Security Groups
10. VPC and networking

---

## 🛠️ Common Operations

### Update Backend Code

**Option 1: SSH into EC2**
```bash
# Connect to EC2
ssh -i CareFlowAI-Key.pem ubuntu@<ec2-public-ip>

# Update code
cd /opt/careflowai
git pull origin main

# Restart service
sudo systemctl restart careflowai-backend

# Check status
sudo systemctl status careflowai-backend
```

**Option 2: Redeploy**
```bash
cd aws/scripts
bash deploy-app.sh
```

### Update Frontend

```bash
cd aws/scripts
bash deploy-frontend.sh

# Invalidate CloudFront cache (if needed)
aws cloudfront create-invalidation \
  --distribution-id <distribution-id> \
  --paths "/*"
```

### View Backend Logs

```bash
# SSH into EC2
ssh -i CareFlowAI-Key.pem ubuntu@<ec2-public-ip>

# View logs (follow)
sudo journalctl -u careflowai-backend -f

# View last 100 lines
sudo journalctl -u careflowai-backend -n 100

# View logs with errors
sudo journalctl -u careflowai-backend -p err
```

### Scale Instances

```bash
# Set desired capacity (1-3 instances)
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name CareFlowAI-Backend-ASG \
  --desired-capacity 3

# Update min/max capacity
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name CareFlowAI-Backend-ASG \
  --min-size 2 \
  --max-size 5
```

### Check Health Status

```bash
# ALB target health
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn>

# Auto Scaling Group health
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names CareFlowAI-Backend-ASG \
  --query 'AutoScalingGroups[0].Instances[*].[InstanceId,HealthStatus,LifecycleState]' \
  --output table
```

---

## 🔒 Security Features

### Network Security
- ✅ **VPC Isolation**: Private and public subnets across 2 Availability Zones
- ✅ **Security Groups**: Restrictive inbound/outbound rules
- ✅ **ALB Security**: Only HTTPS (443) and HTTP (80) exposed
- ✅ **EC2 Security**: Only accessible via ALB, SSH from specific IP

### Application Security
- ✅ **HTTPS**: CloudFront SSL/TLS certificate
- ✅ **JWT Authentication**: Secure token-based auth
- ✅ **CORS**: Configured origins
- ✅ **Encrypted Storage**: EBS volumes encrypted at rest
- ✅ **IAM Roles**: EC2 instance roles for AWS service access

### Access Control
- ✅ **SSH Key Pair**: Secure EC2 access
- ✅ **API Rate Limiting**: API Gateway throttling
- ✅ **CloudWatch Alarms**: Security event notifications

---

## 📊 Monitoring

### CloudWatch Dashboards

Automatic monitoring for:
- CPU Utilization
- Memory Usage
- Network In/Out
- Request Count
- Response Time
- Error Rate
- Disk Usage

### CloudWatch Alarms

Email alerts for:
- High CPU (>80%)
- High memory usage (>80%)
- High error rate (>5%)
- Low healthy host count
- Disk space low (<20%)

### Log Groups

- `/aws/ec2/careflowai/backend` - Application logs
- `/aws/lambda/careflowai` - Lambda function logs (if used)
- `/aws/apigateway/careflowai` - API Gateway logs

### Viewing Metrics

```bash
# CPU utilization (last hour)
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=AutoScalingGroupName,Value=CareFlowAI-Backend-ASG \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average

# Request count (last hour)
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name RequestCount \
  --dimensions Name=LoadBalancer,Value=<load-balancer-id> \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```

---

## 🆘 Troubleshooting

### Backend Not Responding

```bash
# Check EC2 instance status
aws ec2 describe-instance-status --instance-ids <instance-id>

# SSH and check service
ssh -i CareFlowAI-Key.pem ubuntu@<ec2-ip>
sudo systemctl status careflowai-backend

# Restart service
sudo systemctl restart careflowai-backend

# Check logs
sudo journalctl -u careflowai-backend -n 100 --no-pager
```

### Frontend Not Loading

```bash
# Check CloudFront distribution status
aws cloudfront get-distribution --id <distribution-id>

# Invalidate cache
aws cloudfront create-invalidation \
  --distribution-id <distribution-id> \
  --paths "/*"

# Check S3 bucket
aws s3 ls s3://careflowai-frontend/
```

### Auto Scaling Not Working

```bash
# Check scaling activities
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name CareFlowAI-Backend-ASG \
  --max-records 10

# Check scaling policies
aws autoscaling describe-policies \
  --auto-scaling-group-name CareFlowAI-Backend-ASG
```

### ALB Health Checks Failing

```bash
# Check target health
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn>

# SSH to instance and test health endpoint
curl http://localhost:8000/health

# Check security group rules
aws ec2 describe-security-groups \
  --group-ids <security-group-id>
```

### High Costs

```bash
# Check Cost Explorer
aws ce get-cost-and-usage \
  --time-period Start=2025-12-01,End=2025-12-12 \
  --granularity MONTHLY \
  --metrics BlendedCost

# Check running instances
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,LaunchTime]' \
  --output table

# Stop unused instances
aws ec2 stop-instances --instance-ids <instance-id>
```

---

## 📚 Additional Resources

### AWS Documentation
- [CloudFormation User Guide](https://docs.aws.amazon.com/cloudformation/)
- [EC2 User Guide](https://docs.aws.amazon.com/ec2/)
- [Auto Scaling User Guide](https://docs.aws.amazon.com/autoscaling/)
- [ALB User Guide](https://docs.aws.amazon.com/elasticloadbalancing/)
- [API Gateway Developer Guide](https://docs.aws.amazon.com/apigateway/)
- [CloudFront Developer Guide](https://docs.aws.amazon.com/cloudfront/)
- [CloudWatch User Guide](https://docs.aws.amazon.com/cloudwatch/)

### CareFlowAI Documentation
- [Backend README](../backend/README.md) - Backend API documentation
- [Frontend README](../frontend/README.md) - Frontend setup and development
- [Root README](../README.md) - Project overview and features

---

## 📞 Support

1. **Check Documentation**: Review the documentation files in this directory
2. **CloudWatch Logs**: Check application and system logs
3. **CloudFormation Events**: Review stack events for deployment issues
4. **AWS Support**: Contact AWS Support for infrastructure issues
5. **GitHub Issues**: Report bugs and feature requests

---

**Ready to deploy?** Start with [QuickStart.md](./QuickStart.md)!

**Need detailed steps?** See [Deployment_order_and_commands.md](./Deployment_order_and_commands.md)

**Architecture questions?** Read [Deployment_architecture.md](./Deployment_architecture.md)

---

Built with care for better healthcare.
