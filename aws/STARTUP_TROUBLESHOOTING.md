# Startup Script Troubleshooting Guide

## Common Issues and Solutions

### Issue 1: "No AWS Resources Found"

**Symptoms:**
```
NO AWS RESOURCES FOUND
It appears you haven't deployed the CareFlowAI infrastructure yet.
```

**Solution:**
You need to deploy the infrastructure first. Choose one of these options:

#### Option A: Deploy using CloudFormation (Recommended)
```bash
cd aws/scripts
# Edit deploy-infrastructure.sh first - set KEY_NAME variable
bash deploy-infrastructure.sh
```

#### Option B: Check if resources exist in different region
```bash
# Check all regions for instances
aws ec2 describe-regions --query 'Regions[].RegionName' --output text | \
while read region; do
    echo "Checking $region..."
    aws ec2 describe-instances --region $region --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`].Value|[0]]' --output table
done
```

If you find resources in a different region, edit the startup script:
```bash
# Edit aws/startup-aws-resources.sh
AWS_REGION="your-region"  # Change from us-east-1 to your region
```

---

### Issue 2: "AWS CLI not configured"

**Symptoms:**
```
Unable to locate credentials
```

**Solution:**
Configure AWS CLI with your credentials:

```bash
aws configure
```

Enter:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (e.g., us-east-1)
- Default output format (json)

---

### Issue 3: Script exits immediately

**Symptoms:**
Script exits without doing anything when you run it.

**Cause:**
You didn't type "yes" at the confirmation prompt.

**Solution:**
```bash
# Run the script and type "yes" when prompted
bash aws/startup-aws-resources.sh
# When asked: Do you want to proceed with starting resources?
# Type: yes
```

Or run non-interactively:
```bash
echo "yes" | bash aws/startup-aws-resources.sh
```

---

### Issue 4: Permission denied when running script

**Symptoms:**
```
bash: ./startup-aws-resources.sh: Permission denied
```

**Solution:**
Make the script executable:

```bash
chmod +x aws/startup-aws-resources.sh
./aws/startup-aws-resources.sh
```

Or run with bash directly:
```bash
bash aws/startup-aws-resources.sh
```

---

### Issue 5: Resources exist but script doesn't find them

**Symptoms:**
You know you have EC2 instances but script says "No stopped EC2 instances found".

**Cause:**
- Resources might be running already
- Resources might not have the expected tags or names
- Resources might be in a different region

**Solution:**

1. **Check if instances are already running:**
```bash
aws ec2 describe-instances --region us-east-1 \
    --query 'Reservations[].Instances[].[InstanceId,State.Name,Tags[?Key==`Name`].Value|[0]]' \
    --output table
```

2. **Check CloudFormation stacks:**
```bash
aws cloudformation list-stacks --region us-east-1 \
    --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
    --query 'StackSummaries[*].[StackName,StackStatus]' \
    --output table
```

3. **Update script configuration:**
If your stack names are different, edit `aws/startup-aws-resources.sh`:
```bash
CLOUDFORMATION_STACK_PREFIX="YourStackPrefix"  # Change from CareFlowAI
```

---

### Issue 6: DocumentDB errors

**Symptoms:**
```
An error occurred (DBClusterNotFoundFault)
```

**Cause:**
You're using MongoDB Atlas (cloud) instead of DocumentDB (AWS managed).

**Solution:**
This is normal! The script checks for DocumentDB but you might be using MongoDB Atlas instead. The warning can be ignored if you're using MongoDB Atlas.

To remove the warning, you can comment out the DocumentDB section in the script or use MongoDB Atlas as intended.

---

### Issue 7: "Instance is in state: terminated"

**Symptoms:**
Script finds instances but they're terminated.

**Solution:**
Terminated instances cannot be restarted. You need to:

1. **Redeploy the infrastructure:**
```bash
cd aws/scripts
bash deploy-infrastructure.sh
```

2. **Or create new instances manually via AWS Console**

---

## Verifying Your Current AWS Resources

Run these commands to see what you currently have deployed:

```bash
# 1. Check CloudFormation stacks
aws cloudformation list-stacks \
    --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
    --query 'StackSummaries[*].[StackName,StackStatus]' \
    --output table

# 2. Check EC2 instances
aws ec2 describe-instances \
    --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress,Tags[?Key==`Name`].Value|[0]]' \
    --output table

# 3. Check DocumentDB clusters
aws docdb describe-db-clusters \
    --query 'DBClusters[*].[DBClusterIdentifier,Status]' \
    --output table

# 4. Check EKS clusters
aws eks list-clusters --query 'clusters[]' --output table
```

---

## Getting Help

If you're still having issues:

1. **Check AWS CLI configuration:**
   ```bash
   aws configure list
   aws sts get-caller-identity
   ```

2. **Check the detailed logs:**
   Run the script with bash debugging:
   ```bash
   bash -x aws/startup-aws-resources.sh
   ```

3. **Review the deployment guides:**
   - `AWS_DEPLOYMENT_GUIDE.md`
   - `aws/README.md`
   - `AWS_ARCHITECTURE_GUIDE.md`

4. **Verify AWS permissions:**
   Your IAM user needs permissions for:
   - EC2 (describe-instances, start-instances)
   - CloudFormation (describe-stacks)
   - DocumentDB (describe-db-clusters, start-db-cluster)
   - EKS (describe-cluster, list-nodegroups)

---

## Quick Start Checklist

Before running the startup script, verify:

- [ ] AWS CLI is installed (`aws --version`)
- [ ] AWS CLI is configured (`aws configure list`)
- [ ] You have deployed infrastructure (`aws ec2 describe-instances`)
- [ ] You know which region your resources are in
- [ ] You have appropriate IAM permissions

If all checks pass and you still have issues, run:
```bash
bash -x aws/startup-aws-resources.sh 2>&1 | tee startup-debug.log
```

Then review `startup-debug.log` for detailed error messages.
