# Environment Variables Guide

This guide explains all environment variables used in CareFlowAI and how to configure them.

## Overview

The application uses **three different types of credentials**:
1. **JWT Authentication Keys** - For user login/authentication
2. **AWS Credentials** - For AWS cloud deployment
3. **Google Gemini API Key** - For AI services

## Important: These Are NOT the Same!

⚠️ **Common Confusion:**
- `JWT_SECRET_KEY` ≠ `AWS_SECRET_ACCESS_KEY`
- They serve completely different purposes
- You need to configure ALL of them for full functionality

---

## Environment Variables Breakdown

### 1. Database Configuration

```env
MONGODB_URL=mongodb://localhost:27017
DATABASE_NAME=careflowai
```

**Purpose**: Connect to MongoDB database

**How to Get**:
- **Local Development**: Use `mongodb://localhost:27017`
- **MongoDB Atlas**: Get connection string from [MongoDB Atlas](https://cloud.mongodb.com/)
- **AWS DocumentDB**: Get endpoint from AWS Console

---

### 2. JWT Authentication (NOT AWS!)

```env
JWT_SECRET_KEY=your-jwt-secret-key-change-this-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
```

**Purpose**: Sign and verify JWT tokens for user authentication (login sessions)

**How to Generate JWT_SECRET_KEY**:
```bash
# Option 1: Python
python -c "import secrets; print(secrets.token_urlsafe(32))"

# Option 2: OpenSSL
openssl rand -base64 32

# Example output:
# xK8vN2pQ9wR7yZ4mL6tH3jS5fD8gA1cB9eW0rT6uY2
```

**Important**:
- This is for **JWT tokens only**
- NOT related to AWS
- Change this in production
- Keep it secret and secure

**What it Does**:
- When users login, creates encrypted token
- Token proves user identity
- Used for "Bearer token" authentication

---

### 3. File Upload Configuration

```env
UPLOAD_DIR=./uploads
MAX_UPLOAD_SIZE=10485760
```

**Purpose**: Where to store uploaded health reports

**Settings**:
- `UPLOAD_DIR`: Directory path (default: `./uploads`)
- `MAX_UPLOAD_SIZE`: Max file size in bytes (10485760 = 10MB)

---

### 4. AWS Credentials (For Cloud Deployment)

```env
AWS_ACCESS_KEY_ID=your-aws-access-key-id
AWS_SECRET_ACCESS_KEY=your-aws-secret-access-key
AWS_REGION=us-east-1
```

**Purpose**: Authenticate with AWS services (S3, EKS, DocumentDB, etc.)

**How to Get**:
1. Go to [AWS IAM Console](https://console.aws.amazon.com/iam/)
2. Click "Users" → Your username
3. Click "Security credentials" tab
4. Click "Create access key"
5. Download and save:
   - Access Key ID (public)
   - Secret Access Key (private - shown only once!)

**Example**:
```env
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
AWS_REGION=us-east-1
```

**Regions**:
- `us-east-1` - US East (N. Virginia)
- `us-west-2` - US West (Oregon)
- `eu-west-1` - Europe (Ireland)
- [Full list](https://docs.aws.amazon.com/general/latest/gr/rande.html)

**Important**:
- ⚠️ **NEVER commit to Git**
- These give full access to your AWS account
- Rotate keys regularly
- Use IAM roles in production instead

---

### 5. Google Gemini AI API

```env
GEMINI_API_KEY=your-gemini-api-key-here
GEMINI_REPORT_ANALYSIS_MODEL=gemini-2.5-flash
GEMINI_TUTOR_MODEL=gemini-2.5-flash
```

**Purpose**: Access Google Gemini AI for health report analysis and medical tutor

**How to Get GEMINI_API_KEY**:
1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with Google account
3. Click "Get API Key" or "Create API Key"
4. Copy the key (starts with "AI...")

**Example**:
```env
GEMINI_API_KEY=AIzaSyD-XXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

**Model Options**:
- `gemini-2.5-flash` - Latest, fastest (recommended)
- `gemini-1.5-flash` - Stable alternative
- `gemini-1.5-pro` - Most powerful
- `gemini-2.0-flash-exp` - Experimental

**Cost**:
- Free tier: 60 requests/min, 1500/day
- [Pricing details](https://ai.google.dev/pricing)

---

## Complete .env File Example

Here's what a complete `.env` file looks like:

```env
# Database Configuration
MONGODB_URL=mongodb://localhost:27017
DATABASE_NAME=careflowai

# JWT Authentication (NOT AWS!)
# Generate with: python -c "import secrets; print(secrets.token_urlsafe(32))"
JWT_SECRET_KEY=xK8vN2pQ9wR7yZ4mL6tH3jS5fD8gA1cB9eW0rT6uY2
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# File Upload Configuration
UPLOAD_DIR=./uploads
MAX_UPLOAD_SIZE=10485760

# AWS Credentials (for AWS deployment)
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
AWS_REGION=us-east-1

# Google Gemini AI API
GEMINI_API_KEY=AIzaSyD-XXXXXXXXXXXXXXXXXXXXXXXXXXXX
GEMINI_REPORT_ANALYSIS_MODEL=gemini-2.5-flash
GEMINI_TUTOR_MODEL=gemini-2.5-flash
```

---

## Setup Steps

### 1. Create .env File

```bash
cd backend
cp .env.example .env
```

### 2. Edit .env File

Open `backend/.env` in a text editor and replace all placeholder values:

```bash
# Windows
notepad .env

# Mac/Linux
nano .env
# or
vim .env
```

### 3. Fill in Actual Values

Replace each placeholder:
- ❌ `your-jwt-secret-key-change-this-in-production`
- ✅ `xK8vN2pQ9wR7yZ4mL6tH3jS5fD8gA1cB9eW0rT6uY2`

### 4. Verify Configuration

```bash
# Check if .env file exists
ls -la .env

# Verify it's not empty
cat .env
```

### 5. Restart Backend

```bash
.\venv\Scripts\python.exe run.py
```

---

## Security Best Practices

### 1. Never Commit .env to Git

`.gitignore` should include:
```
.env
.env.local
.env.*.local
```

### 2. Use Different Keys for Different Environments

```
.env.development  # For local development
.env.staging      # For staging environment
.env.production   # For production
```

### 3. Rotate Keys Regularly

- JWT_SECRET_KEY: Every 90 days
- AWS Keys: Every 90 days or when employee leaves
- GEMINI_API_KEY: When suspected compromise

### 4. Use Environment-Specific Configuration

**Development**:
```env
JWT_SECRET_KEY=dev-secret-key-not-for-production
AWS_REGION=us-east-1
```

**Production**:
```env
JWT_SECRET_KEY=super-long-random-production-key
AWS_REGION=us-east-1
```

### 5. Use AWS Secrets Manager in Production

Instead of .env file:
```python
import boto3

def get_secret(secret_name):
    client = boto3.client('secretsmanager', region_name='us-east-1')
    response = client.get_secret_value(SecretId=secret_name)
    return response['SecretString']

JWT_SECRET_KEY = get_secret('careflowai/jwt-secret')
```

---

## Troubleshooting

### Error: "Could not validate credentials"

**Cause**: JWT_SECRET_KEY mismatch

**Solution**:
1. Check `JWT_SECRET_KEY` is set in `.env`
2. Restart backend server
3. Clear browser cookies and login again

### Error: "AWS credentials not found"

**Cause**: AWS keys not configured

**Solution**:
1. Add `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` to `.env`
2. Verify keys are valid in AWS Console
3. Restart backend

### Error: "GEMINI_API_KEY not configured"

**Cause**: Missing Gemini API key

**Solution**:
1. Get API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Add to `.env`: `GEMINI_API_KEY=your-key`
3. Restart backend

### Backend Won't Start

**Checklist**:
- [ ] `.env` file exists in `backend/` directory
- [ ] All required variables are set
- [ ] No syntax errors in `.env` (no spaces around `=`)
- [ ] Correct variable names (case-sensitive)
- [ ] Virtual environment activated

---

## Quick Reference Table

| Variable | Purpose | Where to Get | Required |
|----------|---------|--------------|----------|
| `MONGODB_URL` | Database connection | MongoDB Atlas / Local | ✅ Yes |
| `DATABASE_NAME` | Database name | Choose any name | ✅ Yes |
| `JWT_SECRET_KEY` | JWT token signing | Generate with Python | ✅ Yes |
| `ALGORITHM` | JWT algorithm | Keep as HS256 | ✅ Yes |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | Token expiry | Keep as 30 | ✅ Yes |
| `UPLOAD_DIR` | File storage | Keep as ./uploads | ✅ Yes |
| `MAX_UPLOAD_SIZE` | Max file size | Keep as 10485760 | ✅ Yes |
| `AWS_ACCESS_KEY_ID` | AWS access | AWS IAM Console | ⚠️ For AWS only |
| `AWS_SECRET_ACCESS_KEY` | AWS secret | AWS IAM Console | ⚠️ For AWS only |
| `AWS_REGION` | AWS region | Choose region | ⚠️ For AWS only |
| `GEMINI_API_KEY` | AI services | Google AI Studio | ✅ Yes (for AI) |
| `GEMINI_REPORT_ANALYSIS_MODEL` | AI model | Choose model | ✅ Yes (for AI) |
| `GEMINI_TUTOR_MODEL` | AI model | Choose model | ✅ Yes (for AI) |

---

## Different Keys Summary

### JWT_SECRET_KEY
- **What**: Random string for JWT token encryption
- **Used for**: User authentication (login/logout)
- **Generate**: `python -c "import secrets; print(secrets.token_urlsafe(32))"`
- **Example**: `xK8vN2pQ9wR7yZ4mL6tH3jS5fD8gA1cB9eW0rT6uY2`

### AWS_SECRET_ACCESS_KEY
- **What**: AWS account credential
- **Used for**: Accessing AWS services (S3, EKS, DocumentDB)
- **Generate**: AWS IAM Console
- **Example**: `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`

### GEMINI_API_KEY
- **What**: Google AI API credential
- **Used for**: AI health report analysis and medical tutor
- **Generate**: Google AI Studio
- **Example**: `AIzaSyD-XXXXXXXXXXXXXXXXXXXXXXXXXXXX`

**They are all different and serve different purposes!**

---

## For Production Deployment

### AWS EKS/EC2

Use AWS Secrets Manager:
```bash
# Store secrets
aws secretsmanager create-secret \
  --name careflowai/jwt-secret \
  --secret-string "your-jwt-secret"

aws secretsmanager create-secret \
  --name careflowai/gemini-key \
  --secret-string "your-gemini-key"
```

### Docker

Use environment variables:
```bash
docker run -e JWT_SECRET_KEY="..." -e GEMINI_API_KEY="..." careflowai
```

### Kubernetes

Use ConfigMaps and Secrets:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: careflowai-secrets
type: Opaque
stringData:
  jwt-secret-key: xK8vN2pQ9wR7yZ4mL6tH3jS5fD8gA1cB9eW0rT6uY2
  gemini-api-key: AIzaSyD-XXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

---

## Need Help?

1. Check this guide for variable descriptions
2. Verify `.env` file exists and has correct values
3. Check variable names match exactly (case-sensitive)
4. Restart backend after changes
5. Check backend console logs for error messages
