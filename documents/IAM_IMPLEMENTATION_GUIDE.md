# IAM Implementation Guide for CareFlowAI (Course Project)

## Recommended Simple Implementation: AWS Secrets Manager with IAM

This guide covers the easiest IAM implementation for your course project - using AWS Secrets Manager to securely store database credentials instead of hardcoding them.

---

## Why This Approach?

✅ **Simple** - Just 2 IAM policies needed
✅ **Practical** - Shows real-world security best practice
✅ **Demonstrable** - Easy to explain in presentations
✅ **Quick** - Takes ~30 minutes to implement
✅ **Professional** - Never hardcode credentials (big no-no in production)

---

## Current Problem

Your current setup likely has:
- Database credentials in `.env` file or hardcoded in `backend/app/database.py`
- JWT `SECRET_KEY` hardcoded in `backend/app/utils/auth.py:17`

**Security Issue:** Anyone with access to your code can see your credentials!

---

## Solution: AWS Secrets Manager + IAM

### Architecture Overview

```
┌─────────────────────────────────────────────────┐
│          AWS Secrets Manager                     │
│  - MongoDB Connection String                     │
│  - JWT Secret Key                                │
└──────────────┬──────────────────────────────────┘
               │
               │ (IAM Permission)
               │
┌──────────────▼──────────────────────────────────┐
│          ECS Task Role                           │
│  - Policy: Allow reading secrets                 │
└──────────────┬──────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────┐
│       Your FastAPI Application                   │
│  - Fetches secrets using boto3                   │
│  - Uses credentials to connect to MongoDB        │
└──────────────────────────────────────────────────┘
```

---

## Implementation Steps

### Step 1: Store Secrets in AWS Secrets Manager

#### Option A: Using AWS Console (Easiest for Course Project)

1. Go to AWS Console → **Secrets Manager**
2. Click **"Store a new secret"**
3. Select **"Other type of secret"**
4. Add key-value pairs:
   ```
   Key: MONGODB_URI
   Value: mongodb+srv://username:password@cluster.mongodb.net/careflowai

   Key: SECRET_KEY
   Value: your-super-secret-jwt-key-here-make-it-long-and-random
   ```
5. Secret name: `careflowai/backend/credentials`
6. Click through and create the secret
7. **Note the Secret ARN** - you'll need it for IAM policy

#### Option B: Using AWS CLI

```bash
aws secretsmanager create-secret \
  --name careflowai/backend/credentials \
  --description "CareFlowAI Backend Credentials" \
  --secret-string '{
    "MONGODB_URI":"mongodb+srv://username:password@cluster.mongodb.net/careflowai",
    "SECRET_KEY":"your-super-secret-jwt-key-here"
  }'
```

---

### Step 2: Create IAM Policy for Secret Access

Create file: `infrastructure/iam/secrets-access-policy.json`

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:us-east-1:YOUR_ACCOUNT_ID:secret:careflowai/backend/credentials-*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "arn:aws:kms:us-east-1:YOUR_ACCOUNT_ID:key/*",
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "secretsmanager.us-east-1.amazonaws.com"
        }
      }
    }
  ]
}
```

**Replace:**
- `us-east-1` with your AWS region
- `YOUR_ACCOUNT_ID` with your AWS account ID (find in AWS Console top right)

---

### Step 3: Create ECS Task IAM Role

Create file: `infrastructure/iam/ecs-task-role.json`

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

---

### Step 4: Create IAM Role via AWS Console

1. Go to **IAM → Roles → Create Role**
2. Select **"AWS service"** → **"Elastic Container Service"** → **"Elastic Container Service Task"**
3. Role name: `CareFlowAI-ECS-TaskRole`
4. Click **"Create policy"** → JSON tab
5. Paste the contents from `secrets-access-policy.json`
6. Policy name: `CareFlowAI-SecretsAccess`
7. Attach this policy to your role
8. **Note the Role ARN** - you'll need it in ECS task definition

---

### Step 5: Update Backend Code to Use Secrets Manager

#### Install AWS SDK

Add to `backend/requirements.txt`:
```
boto3==1.28.85
```

Then run:
```bash
pip install boto3
```

#### Create Secrets Utility

Create file: `backend/app/utils/secrets.py`

```python
import boto3
import json
from functools import lru_cache
import os

@lru_cache()
def get_secret(secret_name: str = "careflowai/backend/credentials"):
    """
    Fetch secret from AWS Secrets Manager

    For local development, falls back to environment variables
    """
    # Check if running locally (not in AWS)
    if os.getenv("ENVIRONMENT") == "local":
        return {
            "MONGODB_URI": os.getenv("MONGODB_URI"),
            "SECRET_KEY": os.getenv("SECRET_KEY")
        }

    # Production: Fetch from AWS Secrets Manager
    region_name = os.getenv("AWS_REGION", "us-east-1")

    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
        secret = json.loads(get_secret_value_response['SecretString'])
        return secret
    except Exception as e:
        print(f"Error retrieving secret: {e}")
        raise e
```

---

### Step 6: Update Database Configuration

Modify `backend/app/database.py`:

**Before (Insecure):**
```python
from motor.motor_asyncio import AsyncIOMotorClient
import os

MONGODB_URI = os.getenv("MONGODB_URI", "mongodb://localhost:27017")
```

**After (Secure):**
```python
from motor.motor_asyncio import AsyncIOMotorClient
from app.utils.secrets import get_secret

# Fetch credentials from AWS Secrets Manager
secrets = get_secret()
MONGODB_URI = secrets["MONGODB_URI"]
```

---

### Step 7: Update Auth Configuration

Modify `backend/app/utils/auth.py` (line 17):

**Before:**
```python
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-change-this-in-production")
```

**After:**
```python
from app.utils.secrets import get_secret

secrets = get_secret()
SECRET_KEY = secrets["SECRET_KEY"]
```

---

### Step 8: Update ECS Task Definition

When creating your ECS task definition, add the task role:

Create/update: `infrastructure/ecs/backend-task-definition.json`

```json
{
  "family": "careflowai-backend",
  "taskRoleArn": "arn:aws:iam::YOUR_ACCOUNT_ID:role/CareFlowAI-ECS-TaskRole",
  "executionRoleArn": "arn:aws:iam::YOUR_ACCOUNT_ID:role/ecsTaskExecutionRole",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [
    {
      "name": "careflowai-backend",
      "image": "YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/careflowai-backend:latest",
      "portMappings": [
        {
          "containerPort": 8000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "ENVIRONMENT",
          "value": "production"
        },
        {
          "name": "AWS_REGION",
          "value": "us-east-1"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/careflowai-backend",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

**Key Points:**
- `taskRoleArn`: The IAM role we created that allows reading secrets
- `executionRoleArn`: Standard ECS execution role (AWS managed)
- No hardcoded credentials in environment variables!

---

### Step 9: Local Development Setup

Update `.env` file for local development:

```
ENVIRONMENT=local
MONGODB_URI=mongodb://localhost:27017/careflowai
SECRET_KEY=local-dev-secret-key-not-for-production
AWS_REGION=us-east-1
```

Add to `.gitignore`:
```
.env
backend/.env
```

---

## Testing the Implementation

### Test Locally

```bash
cd backend
export ENVIRONMENT=local
python run.py
```

Should connect to local MongoDB using `.env` credentials.

### Test on AWS

When deployed to ECS:
1. Container starts
2. `get_secret()` is called
3. IAM role allows access to Secrets Manager
4. Credentials are fetched
5. Application connects to MongoDB Atlas/DocumentDB

---

## Benefits for Your Course Project Presentation

### What to Say in Demo:

1. **Security Best Practice**
   - "We don't hardcode credentials in our code"
   - "All sensitive data is stored in AWS Secrets Manager"

2. **IAM Integration**
   - "We use IAM roles to grant our application access to secrets"
   - "Only our ECS tasks can read these credentials, following least privilege principle"

3. **Environment Separation**
   - "Local development uses `.env` file"
   - "Production uses AWS Secrets Manager"
   - "Same codebase works in both environments"

4. **Professional Approach**
   - "This is how real-world applications manage credentials"
   - "Prevents credential leaks in version control"

---

## IAM Concepts Demonstrated

✅ **IAM Roles** - ECS Task Role
✅ **IAM Policies** - Secrets Manager access policy
✅ **Least Privilege** - Only specific secrets can be accessed
✅ **Service Integration** - ECS + Secrets Manager
✅ **Trust Policies** - ECS service can assume the role

---

## File Structure

After implementation, your project structure:

```
CareFlowAI/
├── infrastructure/
│   ├── iam/
│   │   ├── ecs-task-role.json
│   │   └── secrets-access-policy.json
│   └── ecs/
│       └── backend-task-definition.json
├── backend/
│   ├── app/
│   │   ├── utils/
│   │   │   ├── auth.py (updated)
│   │   │   └── secrets.py (new)
│   │   └── database.py (updated)
│   ├── requirements.txt (boto3 added)
│   └── .env (local only, in .gitignore)
├── .gitignore (updated)
└── IAM_IMPLEMENTATION_GUIDE.md (this file)
```

---

## Cost Considerations

**AWS Secrets Manager Pricing:**
- $0.40 per secret per month
- $0.05 per 10,000 API calls

**For your course project:**
- 1 secret = $0.40/month
- Minimal API calls = ~$0.01/month
- **Total: Less than $0.50/month**

---

## Troubleshooting

### Error: "Access Denied" when fetching secret

**Solution:** Check:
1. IAM role ARN is correct in ECS task definition
2. Secret ARN in policy matches actual secret name
3. Policy is attached to the role

### Error: "Secret not found"

**Solution:**
- Verify secret name: `careflowai/backend/credentials`
- Check AWS region matches

### Local development not working

**Solution:**
- Ensure `ENVIRONMENT=local` is set
- Verify `.env` file exists with required variables

---

## Alternative IAM Options (If You Want More Complexity)

If your professor wants to see more IAM usage, you can add:

### Option 2: S3 + IAM for File Storage
- Store patient documents in S3
- IAM policy for upload/download
- Pre-signed URLs

### Option 3: AWS Cognito
- Replace JWT with Cognito User Pools
- Federated authentication
- MFA support

### Option 4: API Gateway with IAM Auth
- Lambda functions instead of ECS
- IAM-based API authorization

**But for a course project, Secrets Manager + IAM is sufficient and professional!**

---

## Resources

- [AWS Secrets Manager Documentation](https://docs.aws.amazon.com/secretsmanager/)
- [IAM Roles for ECS Tasks](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html)
- [Boto3 Secrets Manager](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager.html)

---

## Questions for Your Professor/TA

1. "We implemented IAM with Secrets Manager - would you like to see other IAM use cases?"
2. "Should we demonstrate cross-account access or is single-account sufficient?"
3. "Would you like us to add CloudTrail logging for audit trails?"

Good luck with your project! 🚀
