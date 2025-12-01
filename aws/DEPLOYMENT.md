# CareFlowAI AWS Infrastructure

Complete AWS infrastructure setup with Auto Scaling Group, Application Load Balancer, and CloudWatch monitoring.

## Architecture Overview

```
Internet
   ↓
CloudFront (Frontend - S3)
   ↓
Application Load Balancer
   ↓
Auto Scaling Group (EC2 Instances)
   ↓
MongoDB Atlas
   ↓
Google Gemini API
```

## Infrastructure Components

### 1. **VPC & Networking** (`vpc.yaml`)
- VPC with CIDR 10.0.0.0/16
- 2 Public Subnets across 2 Availability Zones
- Internet Gateway
- Route Tables

### 2. **Application Load Balancer** (`alb.yaml`)
- Internet-facing ALB
- Target Group for backend instances (port 8000)
- Health checks on `/health` endpoint
- HTTP listener (port 80)
- Security groups for ALB and backend instances

### 3. **Auto Scaling Group** (`asg.yaml`)
- Launch Template with Ubuntu 22.04
- Automatic scaling based on CPU and request count
- Min: 1, Max: 3, Desired: 1 (configurable)
- CloudWatch Agent for metrics
- Automated instance setup with UserData
- IAM roles and instance profiles

### 4. **CloudWatch Monitoring** (`cloudwatch.yaml`)
- Log Groups for application logs
- CloudWatch Alarms:
  - High ALB latency
  - Unhealthy hosts
  - 5XX errors
  - High CPU usage
  - Low instance count
  - High memory usage
  - High disk usage
- SNS Topic for alarm notifications
- CloudWatch Dashboard with key metrics
- Composite alarms for critical issues

### 5. **S3 & CloudFront** (`s3-cloudfront.yaml`)
- S3 bucket for React frontend
- CloudFront distribution for CDN
- Custom error pages for React Router

## Deployment Guide

### Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** installed and configured
3. **EC2 Key Pair** created in your region
4. **MongoDB Atlas** cluster (or MongoDB connection URL)
5. **Google Gemini API Key**

### Step 1: Prepare Configuration

Before deployment, ensure you have:

```bash
# Required information
- EC2 Key Pair Name
- MongoDB Connection URL
- Google Gemini API Key
- JWT Secret Key (can be auto-generated)
- Email for CloudWatch alarms
```

### Step 2: Deploy Infrastructure

#### Option A: Using the deployment script (Recommended)

```bash
cd aws/scripts
chmod +x deploy-stack.sh
./deploy-stack.sh
```

The script will:
1. Validate AWS credentials
2. Prompt for required parameters
3. Upload CloudFormation templates to S3
4. Deploy the complete infrastructure stack
5. Display outputs including ALB DNS

#### Option B: Manual deployment via AWS Console

1. Upload all YAML files to an S3 bucket
2. Deploy `master-stack.yaml` via CloudFormation Console
3. Provide required parameters
4. Wait for stack creation (10-15 minutes)

#### Option C: Using AWS CLI

```bash
# Create S3 bucket for templates
aws s3 mb s3://careflowai-cf-templates

# Upload templates
aws s3 sync cloudformation/ s3://careflowai-cf-templates/

# Deploy stack
aws cloudformation create-stack \
  --stack-name CareFlowAI-Infrastructure \
  --template-body file://cloudformation/master-stack.yaml \
  --parameters \
    ParameterKey=KeyName,ParameterValue=YOUR_KEY_NAME \
    ParameterKey=MongoDBURL,ParameterValue=YOUR_MONGO_URL \
    ParameterKey=GeminiAPIKey,ParameterValue=YOUR_GEMINI_KEY \
    ParameterKey=SecretKey,ParameterValue=YOUR_SECRET_KEY \
    ParameterKey=AlarmEmail,ParameterValue=your@email.com \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

### Step 3: Deploy Application Code

After infrastructure is ready:

```bash
cd aws/scripts
chmod +x deploy-app.sh
./deploy-app.sh
```

This script will:
1. Find all healthy instances in the ASG
2. Package the backend application
3. Deploy to all instances via SSH
4. Restart the application service

### Step 4: Update Frontend Configuration

Update your frontend environment variables:

```bash
# frontend/.env
VITE_API_URL=http://YOUR_ALB_DNS
```

Rebuild and redeploy frontend:

```bash
cd frontend
npm run build
aws s3 sync dist/ s3://YOUR_FRONTEND_BUCKET/
aws cloudfront create-invalidation --distribution-id YOUR_DIST_ID --paths "/*"
```

## Stack Outputs

After deployment, you'll receive:

- **LoadBalancerDNS**: ALB endpoint for API
- **APIURL**: Base API URL (`http://ALB_DNS`)
- **HealthCheckURL**: Health check endpoint
- **DocsURL**: Swagger API documentation
- **DashboardURL**: CloudWatch dashboard
- **AutoScalingGroupName**: ASG name for management

## Monitoring & Operations

### CloudWatch Dashboard

Access your dashboard at:
```
https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=CareFlowAI-Dashboard
```

**Dashboard includes:**
- Request counts and response codes
- Response time (average and P99)
- Target health
- ASG instance counts
- CPU utilization
- Memory and disk usage
- Active connections
- Recent error logs

### CloudWatch Alarms

Email notifications will be sent when:
- ALB response time > 1 second
- Unhealthy hosts detected
- 5XX errors > 10 in 5 minutes
- CPU usage > 80%
- Instance count < 2
- Memory usage > 85%
- Disk usage > 80%

**Confirm SNS subscription**: Check your email for the subscription confirmation.

### Logs

View logs in CloudWatch Logs:

```bash
# Application logs
/careflowai/backend/{instance-id}/app.log

# Error logs
/careflowai/backend/{instance-id}/error.log

# Instance setup logs
/careflowai/backend/{instance-id}/user-data.log
```

## Scaling Configuration

### Auto Scaling Policies

1. **CPU-based Scaling**: Target 70% CPU utilization
2. **Request-based Scaling**: Target 1000 requests per target

### Manual Scaling

```bash
# Update desired capacity
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name CareFlowAI-Backend-ASG \
  --desired-capacity 3

# Update min/max capacity
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name CareFlowAI-Backend-ASG \
  --min-size 2 \
  --max-size 5
```

## Instance Management

### SSH into instances

```bash
# Get instance IPs
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names CareFlowAI-Backend-ASG \
  --query 'AutoScalingGroups[0].Instances[].InstanceId'

# Get public IP
aws ec2 describe-instances \
  --instance-ids i-xxxxx \
  --query 'Reservations[0].Instances[0].PublicIpAddress'

# SSH
ssh -i your-key.pem ubuntu@INSTANCE_IP
```

### Check application status

```bash
sudo systemctl status careflowai
sudo journalctl -u careflowai -f
```

### Restart application

```bash
sudo systemctl restart careflowai
```

## Cost Optimization

### Estimated Monthly Costs (us-east-1)

| Resource | Configuration | Est. Cost |
|----------|--------------|-----------|
| EC2 (t3.small) | 2 instances | ~$30 |
| ALB | 1 load balancer | ~$20 |
| Data Transfer | ~100 GB | ~$9 |
| CloudWatch | Logs + Metrics | ~$10 |
| S3 + CloudFront | Frontend hosting | ~$5 |
| **Total** | | **~$74/month** |

### Cost Savings Tips

1. Use Reserved Instances for predictable workloads (up to 40% savings)
2. Enable S3 Intelligent-Tiering
3. Set CloudWatch log retention to 7-30 days
4. Use spot instances for non-production environments
5. Schedule ASG to scale down during off-hours

## Troubleshooting

### Issue: Instances failing health checks

```bash
# Check target health
aws elbv2 describe-target-health \
  --target-group-arn YOUR_TARGET_GROUP_ARN

# SSH into instance and check
sudo systemctl status careflowai
curl http://localhost:8000/health
```

### Issue: 5XX errors

```bash
# Check application logs
tail -f /var/log/careflowai/error.log

# Check CloudWatch Logs
aws logs tail /careflowai/backend --follow
```

### Issue: High latency

1. Check CloudWatch CPU/Memory metrics
2. Review application logs for slow queries
3. Consider increasing instance size
4. Enable ALB access logs for request analysis

### Issue: ASG not scaling

```bash
# Check scaling activities
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name CareFlowAI-Backend-ASG

# Check CloudWatch alarms
aws cloudwatch describe-alarms \
  --alarm-names CareFlowAI-ASG-High-CPU
```

## Security Considerations

### Current Setup

- ✅ VPC with public subnets
- ✅ Security groups restricting access
- ✅ HTTPS for CloudFront
- ✅ Encrypted EBS volumes
- ✅ IAM roles with minimal permissions
- ✅ Secrets passed via CloudFormation parameters (NoEcho)

### Recommended Improvements

1. **Use AWS Secrets Manager** for sensitive data
2. **Add private subnets** for database tier
3. **Enable ALB access logs** to S3
4. **Add AWS WAF** for web application firewall
5. **Enable VPC Flow Logs** for network monitoring
6. **Use Certificate Manager** for HTTPS on ALB
7. **Implement Route 53** for custom domain
8. **Add AWS Config** for compliance monitoring
9. **Enable GuardDuty** for threat detection
10. **Use Systems Manager Session Manager** instead of SSH

## Updating Infrastructure

### Update stack parameters

```bash
aws cloudformation update-stack \
  --stack-name CareFlowAI-Infrastructure \
  --use-previous-template \
  --parameters \
    ParameterKey=MinSize,ParameterValue=2 \
    ParameterKey=MaxSize,ParameterValue=5 \
  --capabilities CAPABILITY_NAMED_IAM
```

### Update template

```bash
# Upload new template
aws s3 cp cloudformation/asg.yaml s3://YOUR_BUCKET/

# Update stack
aws cloudformation update-stack \
  --stack-name CareFlowAI-Infrastructure \
  --template-url https://YOUR_BUCKET.s3.amazonaws.com/master-stack.yaml \
  --capabilities CAPABILITY_NAMED_IAM
```

## Cleanup

### Delete entire infrastructure

```bash
# Delete CloudFormation stack
aws cloudformation delete-stack \
  --stack-name CareFlowAI-Infrastructure

# Wait for deletion
aws cloudformation wait stack-delete-complete \
  --stack-name CareFlowAI-Infrastructure

# Delete S3 buckets (manual)
aws s3 rb s3://YOUR_FRONTEND_BUCKET --force
aws s3 rb s3://YOUR_TEMPLATE_BUCKET --force
```

## Support & Documentation

- **AWS CloudFormation**: https://docs.aws.amazon.com/cloudformation/
- **Auto Scaling**: https://docs.aws.amazon.com/autoscaling/
- **Application Load Balancer**: https://docs.aws.amazon.com/elasticloadbalancing/
- **CloudWatch**: https://docs.aws.amazon.com/cloudwatch/

## Additional Resources

- [deployment-info.txt](./deployment-info.txt) - Last deployment details
- [CloudFormation Templates](./cloudformation/) - All infrastructure templates
- [Deployment Scripts](./scripts/) - Automation scripts

---

**Need Help?** Check the CloudWatch dashboard and logs first, then review the troubleshooting section above.
