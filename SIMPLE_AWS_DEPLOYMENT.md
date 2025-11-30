# CareFlowAI - Simple AWS Deployment Guide

**For Complete Beginners** 🚀

This guide will help you deploy CareFlowAI to AWS step-by-step, even if you've never used AWS before.

---

## What You're Going to Build

```
┌─────────────────────────────────────────────────────────┐
│                    Your Application                      │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Frontend (React)  ──────────►  Backend (FastAPI)       │
│   Hosted on S3                   Runs on EC2            │
│   Delivered via CloudFront       (Virtual Computer)      │
│                                                          │
│                                  ▼                       │
│                            MongoDB Atlas                 │
│                            (Database - Free)             │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

**Cost**: Free for 12 months (AWS Free Tier) + MongoDB is free forever

---

## Part 1: Before You Start (15 minutes)

### Step 1: Create AWS Account

1. Go to [aws.amazon.com](https://aws.amazon.com)
2. Click "Create an AWS Account"
3. Follow the signup process (you'll need a credit card, but won't be charged if you stay in free tier)
4. Verify your email and phone number

### Step 2: Install AWS CLI on Your Computer

**Windows:**
```bash
# Download and run installer from:
# https://awscli.amazonaws.com/AWSCLIV2.msi
```

**Mac:**
```bash
brew install awscli
```

**Verify installation:**
```bash
aws --version
# Should show: aws-cli/2.x.x
```

### Step 3: Create Access Keys

1. Log into AWS Console: [console.aws.amazon.com](https://console.aws.amazon.com)
2. Click your name (top right) → "Security credentials"
3. Scroll down to "Access keys"
4. Click "Create access key"
5. Select "Command Line Interface (CLI)"
6. Check the box and click "Next"
7. Click "Create access key"
8. **IMPORTANT**: Copy both:
   - Access Key ID (looks like: AKIAIOSFODNN7EXAMPLE)
   - Secret Access Key (looks like: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY)

### Step 4: Configure AWS CLI

Open terminal and run:
```bash
aws configure
```

It will ask you:
```
AWS Access Key ID: [Paste your Access Key ID]
AWS Secret Access Key: [Paste your Secret Access Key]
Default region name: us-east-1
Default output format: json
```

**Test it works:**
```bash
aws sts get-caller-identity
# Should show your account info
```

### Step 5: Create EC2 Key Pair

This is like a password to access your server.

**Option A: Using AWS Console (Easier)**
1. Go to [EC2 Console](https://console.aws.amazon.com/ec2)
2. Click "Key Pairs" (left sidebar under "Network & Security")
3. Click "Create key pair"
4. Name it: `CareFlowAI-Key`
5. Key pair type: RSA
6. Private key format: `.pem`
7. Click "Create"
8. **SAVE THE FILE** - you can't download it again!
9. Move it to a safe place like `C:\Users\YourName\.ssh\CareFlowAI-Key.pem`

**Option B: Using Command Line**
```bash
aws ec2 create-key-pair \
    --key-name CareFlowAI-Key \
    --query 'KeyMaterial' \
    --output text > CareFlowAI-Key.pem

# On Mac/Linux, set permissions:
chmod 400 CareFlowAI-Key.pem
```

### Step 6: Setup MongoDB Atlas (Free Database)

1. Go to [mongodb.com/cloud/atlas](https://www.mongodb.com/cloud/atlas)
2. Click "Try Free"
3. Sign up with Google/Email
4. Choose: **FREE (M0)** - this is free forever!
5. Cloud Provider: AWS
6. Region: us-east-1 (same as your AWS region)
7. Cluster Name: `CareFlowAI`
8. Click "Create"

**Get Your Connection String:**
1. Click "Connect" on your cluster
2. Add your IP address (click "Add Your Current IP Address")
3. Create Database User:
   - Username: `careflowai_user`
   - Password: Create a strong password (save it!)
4. Choose "Connect your application"
5. Copy the connection string (looks like):
   ```
   mongodb+srv://careflowai_user:<password>@careflowai.xxxxx.mongodb.net/
   ```
6. Replace `<password>` with your actual password

---

## Part 2: Deploy Infrastructure (30 minutes)

Now the fun part begins! Let's deploy everything to AWS.

### Step 1: Edit the Deployment Script

Open the file: `aws/scripts/deploy-infrastructure.sh`

Find line 13 and change it:
```bash
KEY_NAME="CareFlowAI-Key"  # The name you created in Part 1, Step 5
```

**That's it!** Just this one line.

### Step 2: Run the Deployment

Open terminal in your project folder:

```bash
cd "E:\UMD\Data 650 - PCS1\Project\CareFlowAI"

# Run the deployment script
bash aws/scripts/deploy-infrastructure.sh
```

**What happens now:**
- Creates a private network (VPC) for your app ⏱️ 2 minutes
- Creates security rules (firewall) ⏱️ 1 minute
- Creates a virtual computer (EC2) ⏱️ 3 minutes
- Creates storage for frontend (S3) ⏱️ 1 minute
- Creates content delivery (CloudFront) ⏱️ 15-20 minutes

**Total time: ~25-30 minutes**

☕ Good time for a coffee break!

### Step 3: Save the Output

When it finishes, you'll see:
```
=========================================
Infrastructure Deployment Complete!
=========================================

VPC ID: vpc-xxxxx
Security Group ID: sg-xxxxx
EC2 Elastic IP: 54.123.45.67  ← SAVE THIS!
S3 Bucket: careflowai-frontend-xxxxx
CloudFront Domain: d111111abcdef8.cloudfront.net
```

**Save these values** - you'll need them!

### Step 4: Update MongoDB Access

1. Go back to [MongoDB Atlas](https://cloud.mongodb.com)
2. Click "Network Access" (left sidebar)
3. Click "Add IP Address"
4. Paste your **EC2 Elastic IP** (from Step 3)
5. Click "Confirm"

---

## Part 3: Deploy Backend (15 minutes)

Now let's put your FastAPI backend on the EC2 server.

### Step 1: Edit Backend Deployment Script

Open: `aws/scripts/deploy-backend.sh`

Change these lines:
```bash
EC2_IP="54.123.45.67"  # Your Elastic IP from Part 2, Step 3
KEY_FILE="C:/Users/YourName/.ssh/CareFlowAI-Key.pem"  # Path to your .pem file
REPO_URL="https://github.com/your-username/CareFlowAI.git"  # Your GitHub repo (if pushed)
MONGODB_URL="mongodb+srv://careflowai_user:yourpassword@careflowai.xxxxx.mongodb.net/"
SECRET_KEY="run-this-command-openssl-rand-hex-32"  # Generate with: openssl rand -hex 32
```

**To generate SECRET_KEY:**
```bash
openssl rand -hex 32
# Copy the output and paste it as SECRET_KEY
```

### Step 2: Copy Files to EC2 (Alternative Method)

If you haven't pushed to GitHub yet, upload files directly:

```bash
# From project root directory
scp -i "C:/Users/YourName/.ssh/CareFlowAI-Key.pem" -r backend ubuntu@54.123.45.67:/tmp/
```

### Step 3: SSH into EC2 and Setup

```bash
# Connect to your server
ssh -i "C:/Users/YourName/.ssh/CareFlowAI-Key.pem" ubuntu@54.123.45.67
```

You're now inside your AWS server! Run these commands:

```bash
# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install Python and dependencies
sudo apt-get install -y python3-pip python3-venv nginx

# Create project directory
sudo mkdir -p /opt/careflowai
sudo chown ubuntu:ubuntu /opt/careflowai

# Move backend files (if using scp method)
cp -r /tmp/backend /opt/careflowai/

# OR clone from GitHub
# cd /opt/careflowai
# git clone https://github.com/your-username/CareFlowAI.git .

# Go to backend directory
cd /opt/careflowai/backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Create .env file
nano .env
```

**Paste this into .env** (press Ctrl+X, then Y, then Enter to save):
```env
MONGODB_URL=mongodb+srv://careflowai_user:yourpassword@careflowai.xxxxx.mongodb.net/
DATABASE_NAME=careflowai
SECRET_KEY=your-generated-secret-key
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
UPLOAD_DIR=/opt/careflowai/backend/uploads
MAX_UPLOAD_SIZE=10485760
GEMINI_API_KEY=your-gemini-key-if-you-have-one
```

```bash
# Create uploads directory
mkdir -p /opt/careflowai/backend/uploads

# Initialize database
python scripts/init_db.py
python scripts/add_admin.py

# Test the backend
python run.py
# Press Ctrl+C to stop after verifying it works
```

### Step 4: Setup Systemd Service (Auto-start)

```bash
# Create service file
sudo nano /etc/systemd/system/careflowai-backend.service
```

**Paste this:**
```ini
[Unit]
Description=CareFlowAI Backend
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/careflowai/backend
Environment="PATH=/opt/careflowai/backend/venv/bin"
ExecStart=/opt/careflowai/backend/venv/bin/python run.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable careflowai-backend
sudo systemctl start careflowai-backend
sudo systemctl status careflowai-backend

# Should show "active (running)"
```

### Step 5: Setup Nginx (Web Server)

```bash
# Create nginx config
sudo nano /etc/nginx/sites-available/careflowai
```

**Paste this:**
```nginx
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/careflowai /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx

# Exit SSH
exit
```

### Step 6: Test Backend

Open browser and go to:
```
http://YOUR_ELASTIC_IP:8000/docs
```

You should see the FastAPI documentation! 🎉

---

## Part 4: Deploy Frontend (10 minutes)

Final step - deploy the React frontend!

### Step 1: Edit Frontend Deployment Script

Open: `aws/scripts/deploy-frontend.sh`

Change these lines:
```bash
S3_BUCKET="careflowai-frontend-xxxxx"  # From Part 2, Step 3
CLOUDFRONT_DISTRIBUTION_ID="E1234567890ABC"  # Get this from AWS Console
API_URL="http://54.123.45.67"  # Your Elastic IP
```

**To get CloudFront Distribution ID:**
1. Go to [CloudFront Console](https://console.aws.amazon.com/cloudfront)
2. Find your distribution
3. Copy the ID (starts with E, like E1234567890ABC)

### Step 2: Run Frontend Deployment

```bash
cd "E:\UMD\Data 650 - PCS1\Project\CareFlowAI"

# Deploy frontend
bash aws/scripts/deploy-frontend.sh
```

This will:
- Install dependencies
- Build your React app
- Upload to S3
- Clear CloudFront cache

### Step 3: Access Your Application

**Frontend URL:** `https://YOUR-CLOUDFRONT-DOMAIN.cloudfront.net`
**Backend API:** `http://YOUR-ELASTIC-IP/docs`

---

## Part 5: Managing Your Application

### Check if Everything is Running

```bash
bash aws/check-resources.sh
```

### Start Stopped Resources

```bash
bash aws/startup-aws-resources.sh
```

### Stop Resources (Save Money)

```bash
# Stop EC2 instance when not using
aws ec2 stop-instances --instance-ids YOUR-INSTANCE-ID
```

### View Backend Logs (SSH into EC2 first)

```bash
ssh -i your-key.pem ubuntu@YOUR-ELASTIC-IP
sudo journalctl -u careflowai-backend -f
```

### Restart Backend Service

```bash
ssh -i your-key.pem ubuntu@YOUR-ELASTIC-IP
sudo systemctl restart careflowai-backend
```

### Update Backend Code

```bash
ssh -i your-key.pem ubuntu@YOUR-ELASTIC-IP
cd /opt/careflowai
git pull origin main
cd backend
source venv/bin/activate
pip install -r requirements.txt
sudo systemctl restart careflowai-backend
```

### Update Frontend

```bash
# Just run the deploy script again
bash aws/scripts/deploy-frontend.sh
```

---

## Troubleshooting

### Problem: Can't SSH into EC2

**Solution:**
```bash
# Check if instance is running
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' --output table

# Start if stopped
aws ec2 start-instances --instance-ids YOUR-INSTANCE-ID

# Check security group allows SSH from your IP
# Go to EC2 Console → Security Groups → Edit inbound rules
```

### Problem: Backend not responding

**Solution:**
```bash
ssh -i your-key.pem ubuntu@YOUR-ELASTIC-IP

# Check if service is running
sudo systemctl status careflowai-backend

# View logs
sudo journalctl -u careflowai-backend -n 50

# Restart service
sudo systemctl restart careflowai-backend
```

### Problem: Can't connect to MongoDB

**Solution:**
1. Check MongoDB Atlas Network Access includes your EC2 Elastic IP
2. Verify connection string in `.env` file
3. Test connection:
```bash
python3 -c "from pymongo import MongoClient; client = MongoClient('YOUR-MONGODB-URL'); print(client.server_info())"
```

### Problem: Frontend shows old version

**Solution:**
```bash
# Invalidate CloudFront cache
aws cloudfront create-invalidation \
    --distribution-id YOUR-DISTRIBUTION-ID \
    --paths "/*"
```

---

## Cost Estimates

### Free Tier (First 12 Months)
- ✅ EC2 t2.micro: FREE (750 hours/month)
- ✅ S3: FREE (5GB storage, 20,000 GET requests)
- ✅ CloudFront: FREE (1TB data transfer)
- ✅ MongoDB Atlas M0: FREE (forever!)

**Total: $0/month**

### After Free Tier
- EC2 t2.micro: ~$8-10/month
- S3 + CloudFront: ~$1-3/month
- MongoDB Atlas M0: FREE (forever!)

**Total: ~$10-15/month**

---

## Delete Everything (Cleanup)

When you're done and want to delete everything:

```bash
bash aws/cleanup-aws-resources.sh
```

**WARNING:** This deletes EVERYTHING and cannot be undone!

---

## Quick Command Reference

```bash
# Check status
bash aws/check-resources.sh

# Start resources
bash aws/startup-aws-resources.sh

# SSH into server
ssh -i your-key.pem ubuntu@YOUR-ELASTIC-IP

# View logs
sudo journalctl -u careflowai-backend -f

# Restart backend
sudo systemctl restart careflowai-backend

# Update code
cd /opt/careflowai && git pull && sudo systemctl restart careflowai-backend
```

---

## Need Help?

1. **Check logs:** All scripts show colored output - red = error, yellow = warning
2. **Verify resources:** Run `bash aws/check-resources.sh`
3. **Review documentation:**
   - `AWS_CLI_COMMANDS.md` - All useful AWS commands
   - `aws/STARTUP_TROUBLESHOOTING.md` - Common issues
   - `QUICK_REFERENCE.md` - Quick command reference

---

## What's Next?

Once deployed, you can:

1. **Add a custom domain** - Point your domain to CloudFront
2. **Enable HTTPS** - Use AWS Certificate Manager (free)
3. **Add monitoring** - Use CloudWatch for logs and metrics
4. **Setup CI/CD** - Auto-deploy on git push
5. **Scale up** - Move to larger instance when needed

Congratulations! Your CareFlowAI application is now live on AWS! 🎉
