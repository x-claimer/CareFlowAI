# CareFlowAI AWS Quick Reference

## Check if Instances are Running

### Method 1: Use the automated checker (Recommended)
```bash
bash aws/check-resources.sh
```

This will show you:
- ✓ CloudFormation stacks
- ✓ EC2 instances (with state: running/stopped)
- ✓ DocumentDB clusters
- ✓ EKS clusters
- ✓ S3 buckets and CloudFront distributions

### Method 2: Quick AWS CLI commands

**Check all EC2 instances:**
```bash
aws ec2 describe-instances --region us-east-1 \
    --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress,Tags[?Key==`Name`].Value|[0]]' \
    --output table
```

**Check only running instances:**
```bash
aws ec2 describe-instances --region us-east-1 \
    --filters "Name=instance-state-name,Values=running" \
    --query 'Reservations[*].Instances[*].[InstanceId,PublicIpAddress]' \
    --output table
```

**Check only stopped instances:**
```bash
aws ec2 describe-instances --region us-east-1 \
    --filters "Name=instance-state-name,Values=stopped" \
    --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0]]' \
    --output table
```

**Count running instances:**
```bash
aws ec2 describe-instances --region us-east-1 \
    --filters "Name=instance-state-name,Values=running" \
    --query 'length(Reservations[*].Instances[*])' \
    --output text
```

### Method 3: Check via CloudFormation

**If you deployed using CloudFormation:**
```bash
# Get instance ID from stack
INSTANCE_ID=$(aws cloudformation describe-stacks \
    --stack-name CareFlowAI-Backend \
    --region us-east-1 \
    --query 'Stacks[0].Outputs[?OutputKey==`InstanceId`].OutputValue' \
    --output text)

# Check instance state
aws ec2 describe-instances --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].[InstanceId,State.Name,PublicIpAddress]' \
    --output table
```

---

## Start/Stop Resources

### Start all resources
```bash
bash aws/startup-aws-resources.sh
```

### Stop specific instance
```bash
# Stop by instance ID
aws ec2 stop-instances --instance-ids i-xxxxxxxxx --region us-east-1

# Or get instance ID from CloudFormation first
INSTANCE_ID=$(aws cloudformation describe-stacks \
    --stack-name CareFlowAI-Backend \
    --region us-east-1 \
    --query 'Stacks[0].Outputs[?OutputKey==`InstanceId`].OutputValue' \
    --output text)
aws ec2 stop-instances --instance-ids $INSTANCE_ID --region us-east-1
```

### Start specific instance
```bash
# Start by instance ID
aws ec2 start-instances --instance-ids i-xxxxxxxxx --region us-east-1

# Wait for it to be running
aws ec2 wait instance-running --instance-ids i-xxxxxxxxx --region us-east-1

# Get the public IP
aws ec2 describe-instances --instance-ids i-xxxxxxxxx \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text
```

---

## Check Instance Details

### Get public IP of running instance
```bash
aws ec2 describe-instances --region us-east-1 \
    --filters "Name=instance-state-name,Values=running" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text
```

### Get instance status
```bash
aws ec2 describe-instance-status \
    --instance-ids i-xxxxxxxxx \
    --region us-east-1 \
    --output table
```

### Get instance console output (for debugging)
```bash
aws ec2 get-console-output \
    --instance-ids i-xxxxxxxxx \
    --region us-east-1 \
    --output text
```

---

## Access Your Application

### Once instances are running:

1. **Get the public IP:**
   ```bash
   PUBLIC_IP=$(aws ec2 describe-instances --region us-east-1 \
       --filters "Name=instance-state-name,Values=running" \
       --query 'Reservations[0].Instances[0].PublicIpAddress' \
       --output text)
   echo "Public IP: $PUBLIC_IP"
   ```

2. **Access the backend:**
   - API: `http://$PUBLIC_IP:8000`
   - API Docs: `http://$PUBLIC_IP:8000/docs`
   - Health Check: `http://$PUBLIC_IP:8000/health`

3. **SSH into the instance:**
   ```bash
   ssh -i your-key.pem ubuntu@$PUBLIC_IP
   ```

---

## Troubleshooting

### No instances found?
```bash
# Check if you have resources deployed
aws cloudformation list-stacks --region us-east-1 \
    --stack-status-filter CREATE_COMPLETE \
    --query 'StackSummaries[*].[StackName]' \
    --output table

# If no stacks, you need to deploy infrastructure first
bash aws/scripts/deploy-infrastructure.sh
```

### Check different region?
```bash
# List all regions
aws ec2 describe-regions --query 'Regions[].RegionName' --output table

# Check specific region
aws ec2 describe-instances --region us-west-2 \
    --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' \
    --output table
```

### Check costs
```bash
# Get current month cost estimate
aws ce get-cost-and-usage \
    --time-period Start=$(date -u +%Y-%m-01),End=$(date -u +%Y-%m-%d) \
    --granularity MONTHLY \
    --metrics BlendedCost \
    --group-by Type=SERVICE
```

---

## Common Instance States

- **pending** - Instance is starting up
- **running** - Instance is running and accessible
- **stopping** - Instance is shutting down
- **stopped** - Instance is stopped (not charged for compute)
- **terminated** - Instance is deleted (cannot be restarted)

---

## Quick Actions Cheat Sheet

```bash
# Check status
bash aws/check-resources.sh

# Start everything
bash aws/startup-aws-resources.sh

# Stop instance to save money
aws ec2 stop-instances --instance-ids i-xxxxx

# Check health
curl http://YOUR_IP:8000/health

# View backend logs (when SSH'd in)
sudo journalctl -u careflowai-backend -f

# Restart backend service (when SSH'd in)
sudo systemctl restart careflowai-backend
```

---

## Additional Resources

- Full CLI reference: `aws/AWS_CLI_COMMANDS.md`
- Deployment guide: `AWS_DEPLOYMENT_GUIDE.md`
- Troubleshooting: `aws/STARTUP_TROUBLESHOOTING.md`
- Architecture overview: `AWS_ARCHITECTURE_GUIDE.md`
