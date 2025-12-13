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
chmod +x deploy-infrastructure.sh
./deploy-infrastructure.sh
```

**When prompted, provide:**
- EC2 Key Pair Name
- Instance Type (default: t2.micro)
- Region (default: us-east-1)

**Wait for stack creation to complete.**

### Step 2: Deploy Backend (2-3 minutes)

Edit `deploy-backend.sh` first:
```bash
EC2_IP="your-elastic-ip-from-step-1"
KEY_FILE="path/to/your-key.pem"
MONGODB_URL="your-mongodb-atlas-url"
SECRET_KEY="$(openssl rand -hex 32)"
```

Then deploy:
```bash
chmod +x deploy-backend.sh
./deploy-backend.sh
```

### Step 3: Deploy Frontend (2 minutes)

Edit `deploy-frontend.sh`:
```bash
S3_BUCKET="your-s3-bucket-from-step-1"
CLOUDFRONT_DISTRIBUTION_ID="your-dist-id-from-step-1"
API_URL="http://your-elastic-ip:8000"
```

Then deploy:
```bash
chmod +x deploy-frontend.sh
./deploy-frontend.sh
```

## Test Your Deployment

```bash
# Test backend
curl http://YOUR_EC2_IP:8000/health

# Expected response:
# {"status":"healthy","service":"CareFlowAI API","database":"MongoDB"}

# Test API docs
open http://YOUR_EC2_IP:8000/docs

# Test frontend
open https://YOUR_CLOUDFRONT_DOMAIN.cloudfront.net
```

## Access Your Services

After deployment:

- **API Endpoint**: `http://YOUR_EC2_IP:8000`
- **API Docs**: `http://YOUR_EC2_IP:8000/docs`
- **Health Check**: `http://YOUR_EC2_IP:8000/health`
- **Frontend**: `https://YOUR_CLOUDFRONT_DOMAIN.cloudfront.net`

## Optional: Deploy with API Gateway

If you want API Gateway:

```bash
# First, deploy ALB manually
aws cloudformation create-stack \
  --stack-name CareFlowAI-ALB \
  --template-body file://aws/cloudformation/alb.yaml \
  --parameters \
    ParameterKey=VPCId,ParameterValue=YOUR_VPC_ID \
    ParameterKey=PublicSubnet1,ParameterValue=SUBNET1_ID \
    ParameterKey=PublicSubnet2,ParameterValue=SUBNET2_ID \
  --region us-east-1

# Wait for ALB to be created, then:
cd aws/scripts
chmod +x deploy-api-gateway.sh
./deploy-api-gateway.sh
```

## Verify Deployment

```bash
# Check all resources
bash aws/check-resources.sh
```

Should show:
- ✅ CloudFormation Stacks
- ✅ EC2 Instances
- ✅ S3 Buckets
- ✅ CloudFront Distribution

## Common Commands

```bash
# View backend logs
ssh -i your-key.pem ubuntu@YOUR_EC2_IP
sudo journalctl -u careflowai-backend -f

# Restart backend
sudo systemctl restart careflowai-backend

# Check backend status
sudo systemctl status careflowai-backend

# Update backend code
cd /opt/careflowai
git pull origin main
cd backend
source venv/bin/activate
pip install -r requirements.txt
sudo systemctl restart careflowai-backend
```

## Troubleshooting

### Problem: Health check failing
```bash
# SSH into instance
ssh -i your-key.pem ubuntu@YOUR_EC2_IP

# Check service
sudo systemctl status careflowai-backend
sudo journalctl -u careflowai-backend -f

# Check if Python process is running
ps aux | grep uvicorn

# Check if port 8000 is listening
sudo netstat -tlnp | grep 8000
```

### Problem: Can't SSH into EC2
- Verify security group allows port 22 from your IP
- Check key file permissions: `chmod 400 your-key.pem`
- Verify you're using the correct key pair

### Problem: Frontend shows blank page
- Check browser console for errors
- Verify API_URL in frontend .env
- Test API endpoint directly: `curl http://YOUR_EC2_IP:8000/health`

### Problem: Database connection error
- Check MongoDB Atlas network access whitelist
- Verify EC2 Elastic IP is whitelisted
- Test connection from EC2:
  ```bash
  python3 -c "from pymongo import MongoClient; client = MongoClient('YOUR_MONGO_URL'); print(client.server_info())"
  ```

## What's Deployed?

- ✅ VPC with 2 availability zones
- ✅ Security Groups
- ✅ EC2 t2.micro instance with Elastic IP
- ✅ S3 bucket for frontend
- ✅ CloudFront distribution
- ✅ IAM roles and policies

## Cost Estimate

### Simple Deployment
- EC2 t2.micro: $8.50/month
- EBS 30GB: $3/month
- S3 + CloudFront: $1-2/month
- **Total: ~$12-15/month**

### With ALB + API Gateway
- EC2 t2.micro: $8.50/month
- ALB: $16.20/month
- API Gateway: $1/month
- S3 + CloudFront: $1-2/month
- CloudWatch: $3/month
- **Total: ~$30-35/month**

## Next Steps

1. ✅ Infrastructure deployed
2. ✅ Backend deployed
3. ✅ Frontend deployed
4. ⏭ Configure custom domain (optional)
5. ⏭ Enable HTTPS on ALB with ACM (optional)
6. ⏭ Set up monitoring and alerts (optional)
7. ⏭ Implement CI/CD pipeline (optional)

## Cleanup

To delete all resources:

```bash
cd aws
bash cleanup-aws-resources.sh
```

⚠️ **Warning**: This permanently deletes all data!

## Need Help?

- Full documentation: [Deployment_order_and_commands.md](./Deployment_order_and_commands.md)
- Architecture details: [Deployment_architecture.md](./Deployment_architecture.md)
- Service info: [Services_used_and_cost_comparison.md](./Services_used_and_cost_comparison.md)

---

**Congratulations!** 🎉 Your CareFlowAI infrastructure is now deployed!
