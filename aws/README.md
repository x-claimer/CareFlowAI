# CareFlowAI AWS Deployment

Complete AWS infrastructure and deployment guide for the CareFlowAI medical management system.

## 📁 Directory Structure

```
aws/
├── cloudformation/              # CloudFormation templates
│   ├── vpc.yaml                # VPC and networking
│   ├── security-groups.yaml    # Security groups
│   ├── ec2-backend.yaml        # EC2 instance for backend
│   ├── s3-cloudfront.yaml      # S3 bucket and CloudFront
│   ├── alb.yaml                # Application Load Balancer
│   ├── asg.yaml                # Auto Scaling Group (t2.micro)
│   ├── api-gateway.yaml        # API Gateway with VPC Link
│   └── cloudwatch.yaml         # Monitoring and alarms
│
├── scripts/                     # Deployment scripts
│   ├── deploy-infrastructure.sh    # Deploy core infrastructure
│   ├── deploy-api-gateway.sh       # Deploy API Gateway
│   ├── deploy-backend.sh           # Deploy FastAPI backend
│   ├── deploy-frontend.sh          # Deploy React frontend
│   └── deploy-app.sh              # Deploy to ASG instances
│
├── check-resources.sh           # Check deployed AWS resources
├── cleanup-aws-resources.sh     # Delete all AWS resources
├── startup-aws-resources.sh     # Start stopped resources
│
├── Readme.md                    # This file
├── QuickStart.md               # 15-minute quick start guide
├── Deployment_architecture.md   # Architecture diagrams and details
├── Deployment_order_and_commands.md  # Step-by-step deployment
└── Services_used_and_cost_comparison.md  # AWS services and costs
```

## 🚀 Quick Links

- **[QuickStart.md](./QuickStart.md)** - Get started in 15 minutes
- **[Deployment_architecture.md](./Deployment_architecture.md)** - Architecture overview
- **[Deployment_order_and_commands.md](./Deployment_order_and_commands.md)** - Detailed deployment steps
- **[Services_used_and_cost_comparison.md](./Services_used_and_cost_comparison.md)** - AWS services and cost analysis

## 🏗️ Architecture Overview

### Production Architecture
```
User
  ↓
CloudFront (React Frontend)
  ↓
API Gateway (HTTP API)
  ↓
VPC Link
  ↓
Application Load Balancer
  ↓
Auto Scaling Group (EC2 t2.micro)
  ↓
FastAPI Backend
  ↓
MongoDB Atlas + Google Gemini AI
```

### Key Features
- ✅ **Auto Scaling**: 1-3 t2.micro instances based on load
- ✅ **Load Balancing**: ALB with health checks
- ✅ **API Management**: API Gateway with rate limiting
- ✅ **Monitoring**: CloudWatch logs, metrics, and alarms
- ✅ **CDN**: CloudFront for global distribution
- ✅ **Cost Optimized**: ~$35-52/month

## 📋 Prerequisites

1. **AWS Account** with admin access
2. **AWS CLI** installed and configured
3. **EC2 Key Pair** created
4. **MongoDB Atlas** connection string
5. **Google Gemini API** key

## 🎯 Deployment Options

### Option 1: Quick Deploy (Recommended for Testing)
```bash
cd aws/scripts
bash deploy-infrastructure.sh
bash deploy-backend.sh
bash deploy-frontend.sh
```
**Time**: ~20 minutes | **Cost**: ~$10-15/month

### Option 2: Full Production Deploy
```bash
cd aws/scripts
bash deploy-infrastructure.sh
bash deploy-api-gateway.sh
bash deploy-backend.sh
bash deploy-frontend.sh
```
**Time**: ~30 minutes | **Cost**: ~$35-52/month

## 📊 AWS Services Used

| Service | Purpose | Cost/Month |
|---------|---------|------------|
| EC2 (t2.micro) | Backend hosting | $8.50 - $25.50 |
| ALB | Load balancing | $16.20 |
| API Gateway | API management | $1.00 |
| CloudFront | CDN | $1.00 |
| S3 | Frontend hosting | $0.50 |
| CloudWatch | Monitoring | $3.00 |
| VPC | Networking | $0.00 |
| **Total** | | **~$35-52** |

## 🔧 Management Scripts

### Check Resources
```bash
bash check-resources.sh
```

### Start Resources
```bash
bash startup-aws-resources.sh
```

### Delete Everything
```bash
bash cleanup-aws-resources.sh
```

## 🛠️ Common Operations

### Update Backend
```bash
ssh -i your-key.pem ubuntu@<ec2-ip>
cd /opt/careflowai && git pull
sudo systemctl restart careflowai-backend
```

### Update Frontend
```bash
cd aws/scripts && bash deploy-frontend.sh
```

### View Logs
```bash
sudo journalctl -u careflowai-backend -f
```

### Scale Instances
```bash
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name CareFlowAI-Backend-ASG \
  --desired-capacity 3
```

## 🔒 Security Features

- ✅ VPC Isolation
- ✅ Security Groups
- ✅ HTTPS (CloudFront)
- ✅ Encrypted EBS
- ✅ IAM Roles
- ✅ API Rate Limiting

## 📈 Monitoring

- CloudWatch Dashboard
- Email alerts
- Log aggregation
- Custom metrics

## 🆘 Troubleshooting

### Backend Not Responding
```bash
sudo systemctl status careflowai-backend
sudo systemctl restart careflowai-backend
sudo journalctl -u careflowai-backend -n 100
```

### Frontend Not Loading
```bash
aws cloudfront create-invalidation --distribution-id <id> --paths "/*"
```

## 📞 Support

1. Check documentation files in this directory
2. Review CloudWatch logs
3. Check CloudFormation stack events

---

**Ready to deploy?** Start with [QuickStart.md](./QuickStart.md)!
