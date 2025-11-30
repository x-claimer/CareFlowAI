# AWS CLI Commands Reference for CareFlowAI

This document contains useful AWS CLI commands for managing CareFlowAI infrastructure.

## Prerequisites

```bash
# Install AWS CLI
pip install awscli

# Configure AWS CLI
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Default region: us-east-1
# Default output format: json
```

## EC2 Commands

### List EC2 Instances
```bash
aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=CareFlowAI-Backend" \
    --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]' \
    --output table
```

### Start EC2 Instance
```bash
aws ec2 start-instances --instance-ids i-xxxxxxxxx
```

### Stop EC2 Instance
```bash
aws ec2 stop-instances --instance-ids i-xxxxxxxxx
```

### Get EC2 Instance Public IP
```bash
aws ec2 describe-instances \
    --instance-ids i-xxxxxxxxx \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text
```

### SSH into EC2
```bash
ssh -i your-key.pem ubuntu@<elastic-ip>
```

## S3 Commands

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

### Delete S3 Bucket
```bash
aws s3 rb s3://your-bucket-name/ --force
```

## CloudFront Commands

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

## CloudFormation Commands

### List Stacks
```bash
aws cloudformation list-stacks \
    --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
    --query 'StackSummaries[*].[StackName,StackStatus]' \
    --output table
```

### Describe Stack
```bash
aws cloudformation describe-stacks --stack-name CareFlowAI-VPC
```

### Get Stack Outputs
```bash
aws cloudformation describe-stacks \
    --stack-name CareFlowAI-Backend \
    --query 'Stacks[0].Outputs' \
    --output table
```

### Delete Stack
```bash
aws cloudformation delete-stack --stack-name CareFlowAI-VPC
```

### Validate CloudFormation Template
```bash
aws cloudformation validate-template \
    --template-body file://aws/cloudformation/vpc.yaml
```

## IAM Commands

### List IAM Roles
```bash
aws iam list-roles --query 'Roles[?contains(RoleName, `CareFlowAI`)].[RoleName]' --output table
```

### Get IAM Role
```bash
aws iam get-role --role-name CareFlowAI-EC2-Role
```

## VPC Commands

### List VPCs
```bash
aws ec2 describe-vpcs \
    --filters "Name=tag:Name,Values=CareFlowAI-VPC" \
    --query 'Vpcs[*].[VpcId,CidrBlock]' \
    --output table
```

### List Security Groups
```bash
aws ec2 describe-security-groups \
    --filters "Name=tag:Name,Values=CareFlowAI-*" \
    --query 'SecurityGroups[*].[GroupId,GroupName]' \
    --output table
```

## Elastic IP Commands

### List Elastic IPs
```bash
aws ec2 describe-addresses \
    --query 'Addresses[*].[PublicIp,InstanceId,AllocationId]' \
    --output table
```

### Associate Elastic IP
```bash
aws ec2 associate-address \
    --instance-id i-xxxxxxxxx \
    --allocation-id eipalloc-xxxxxxxxx
```

### Release Elastic IP
```bash
aws ec2 release-address --allocation-id eipalloc-xxxxxxxxx
```

## CloudWatch Logs Commands

### List Log Groups
```bash
aws logs describe-log-groups \
    --log-group-name-prefix /aws/lambda/careflowai
```

### Get Recent Logs
```bash
aws logs tail /aws/lambda/careflowai-ai-processor --follow
```

## Lambda Commands (Optional - for AI processing)

### List Lambda Functions
```bash
aws lambda list-functions \
    --query 'Functions[?contains(FunctionName, `careflowai`)].[FunctionName,Runtime]' \
    --output table
```

### Invoke Lambda Function
```bash
aws lambda invoke \
    --function-name careflowai-ai-processor \
    --payload '{"task_id":"test-123","data":{}}' \
    response.json
```

### Get Lambda Function Configuration
```bash
aws lambda get-function-configuration \
    --function-name careflowai-ai-processor
```

### Update Lambda Function Code
```bash
aws lambda update-function-code \
    --function-name careflowai-ai-processor \
    --zip-file fileb://function.zip
```

## Resource Management Scripts

### Start All Resources (Automated Script)
```bash
# Start all CareFlowAI AWS resources with one command
bash aws/startup-aws-resources.sh
```

This script will:
- Start DocumentDB cluster instances
- Start EC2 backend instances
- Scale up EKS node groups (if applicable)
- Verify service health
- Display resource summary with URLs and endpoints

### Stop All Resources (Cost Savings)
```bash
# Stop EC2 instances to save costs
aws ec2 stop-instances --instance-ids i-xxxxxxxxx

# Stop DocumentDB cluster
aws docdb stop-db-cluster --db-cluster-identifier careflowai-mongodb

# Scale down EKS node groups to 0
aws eks update-nodegroup-config \
    --cluster-name careflowai-cluster \
    --nodegroup-name careflowai-nodes \
    --scaling-config minSize=0,maxSize=4,desiredSize=0
```

## Resource Cleanup Commands

### Delete All CareFlowAI Resources (BE CAREFUL!)
```bash
# Use the automated cleanup script (RECOMMENDED)
bash aws/cleanup-aws-resources.sh

# OR manually delete CloudFormation stacks in reverse order
aws cloudformation delete-stack --stack-name CareFlowAI-Frontend
aws cloudformation delete-stack --stack-name CareFlowAI-Backend
aws cloudformation delete-stack --stack-name CareFlowAI-SecurityGroups
aws cloudformation delete-stack --stack-name CareFlowAI-VPC

# Wait for deletions to complete
aws cloudformation wait stack-delete-complete --stack-name CareFlowAI-Frontend
aws cloudformation wait stack-delete-complete --stack-name CareFlowAI-Backend
aws cloudformation wait stack-delete-complete --stack-name CareFlowAI-SecurityGroups
aws cloudformation wait stack-delete-complete --stack-name CareFlowAI-VPC
```

## Monitoring Commands

### Get EC2 CPU Utilization (Last Hour)
```bash
aws cloudwatch get-metric-statistics \
    --namespace AWS/EC2 \
    --metric-name CPUUtilization \
    --dimensions Name=InstanceId,Value=i-xxxxxxxxx \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Average
```

### Get S3 Bucket Size
```bash
aws cloudwatch get-metric-statistics \
    --namespace AWS/S3 \
    --metric-name BucketSizeBytes \
    --dimensions Name=BucketName,Value=your-bucket-name Name=StorageType,Value=StandardStorage \
    --start-time $(date -u -d '1 day ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 86400 \
    --statistics Average
```

## Cost Management

### Get Current Month Cost
```bash
aws ce get-cost-and-usage \
    --time-period Start=$(date -u +%Y-%m-01),End=$(date -u +%Y-%m-%d) \
    --granularity MONTHLY \
    --metrics BlendedCost \
    --group-by Type=SERVICE
```

## Troubleshooting Commands

### Check EC2 System Log
```bash
aws ec2 get-console-output --instance-id i-xxxxxxxxx
```

### Check CloudFormation Stack Events
```bash
aws cloudformation describe-stack-events \
    --stack-name CareFlowAI-Backend \
    --max-items 20
```

### Check EC2 Instance Status
```bash
aws ec2 describe-instance-status --instance-ids i-xxxxxxxxx
```

## Backup Commands

### Create EC2 AMI (Backup)
```bash
aws ec2 create-image \
    --instance-id i-xxxxxxxxx \
    --name "CareFlowAI-Backend-Backup-$(date +%Y%m%d)" \
    --description "Backup of CareFlowAI backend"
```

### Create EBS Snapshot
```bash
aws ec2 create-snapshot \
    --volume-id vol-xxxxxxxxx \
    --description "CareFlowAI backup $(date +%Y%m%d)"
```

## Quick Reference

### Get All CareFlowAI Resource IDs
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
