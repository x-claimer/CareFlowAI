# CareFlowAI - Quick Start Guide

Get your CareFlowAI infrastructure up and running in 15 minutes.

## Prerequisites Checklist

- [ ] AWS Account with admin access
- [ ] AWS CLI installed (`aws --version`)
- [ ] AWS credentials configured (`aws configure`)
- [ ] EC2 Key Pair created in us-east-1
- [ ] MongoDB Atlas cluster URL
- [ ] Google Gemini API Key

## Quick Deploy (3 Steps)

### Step 1: Deploy Infrastructure (10-15 minutes)

```bash
cd aws/scripts
chmod +x deploy-stack.sh
./deploy-stack.sh
```

When prompted, provide:
- EC2 Key Pair Name
- MongoDB URL
- Gemini API Key
- Email for alarms
- Instance settings (or use defaults)

**Wait for stack creation to complete.**

### Step 2: Deploy Application (2-3 minutes)

```bash
chmod +x deploy-app.sh
./deploy-app.sh
```

Provide:
- Path to your SSH key (.pem file)

### Step 3: Test Your Deployment

```bash
# Get your ALB DNS from the output, then:
curl http://YOUR_ALB_DNS/health

# Should return: {"status":"healthy","service":"CareFlowAI API","database":"MongoDB"}
```

## Access Your Services

After deployment:

- **API Endpoint**: `http://YOUR_ALB_DNS`
- **API Docs**: `http://YOUR_ALB_DNS/docs`
- **Health Check**: `http://YOUR_ALB_DNS/health`
- **CloudWatch Dashboard**: Check your email for the dashboard link

## Update Frontend

```bash
cd frontend

# Update .env with your ALB DNS
echo "VITE_API_URL=http://YOUR_ALB_DNS" > .env

# Build and deploy
npm run build
```

## Monitor Your Application

1. **CloudWatch Dashboard**: View real-time metrics
2. **CloudWatch Logs**: `/careflowai/backend` log group
3. **Email Alerts**: Confirm SNS subscription in your email

## Common Commands

```bash
# Check ASG instances
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names CareFlowAI-Backend-ASG

# View logs
aws logs tail /careflowai/backend --follow

# Scale up
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name CareFlowAI-Backend-ASG \
  --desired-capacity 3
```

## Troubleshooting

**Problem**: Health check failing
```bash
# SSH into instance
ssh -i your-key.pem ubuntu@INSTANCE_IP

# Check service
sudo systemctl status careflowai
sudo journalctl -u careflowai -f
```

**Problem**: Can't access API
- Check security groups allow port 8000
- Verify ALB target health
- Check CloudWatch logs for errors

**Problem**: 5XX errors
```bash
# View error logs
aws logs tail /careflowai/backend --follow --filter-pattern ERROR
```

## What's Deployed?

- ✅ VPC with 2 availability zones
- ✅ Application Load Balancer
- ✅ Auto Scaling Group (1-3 instances)
- ✅ CloudWatch monitoring & alarms
- ✅ IAM roles and security groups
- ✅ Automated health checks
- ✅ Log aggregation

## Cost Estimate

~$74/month for default configuration:
- 2x t3.small instances: ~$30
- Application Load Balancer: ~$20
- Data transfer: ~$9
- CloudWatch: ~$10
- S3 + CloudFront: ~$5

## Next Steps

1. ✅ Deploy infrastructure
2. ✅ Deploy application
3. ✅ Test API endpoints
4. ⏭ Update frontend configuration
5. ⏭ Configure custom domain (optional)
6. ⏭ Enable HTTPS with ACM (optional)
7. ⏭ Set up CI/CD pipeline (optional)

## Need Help?

- Full documentation: [DEPLOYMENT.md](./DEPLOYMENT.md)
- CloudFormation templates: [cloudformation/](./cloudformation/)
- AWS Support: https://console.aws.amazon.com/support/

---

**Ready to deploy?** Run `./deploy-stack.sh` and follow the prompts!
