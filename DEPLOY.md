# CareFlowAI - Complete Deployment Guide

**Everything you need to deploy CareFlowAI to AWS in one place.**

---

## 📖 Table of Contents

1. [Quick Start](#quick-start) - 5 minute readiness check
2. [Prerequisites](#prerequisites) - What you need before starting
3. [Step 1: Setup](#step-1-setup) - AWS account and tools (15 min)
4. [Step 2: Deploy Infrastructure](#step-2-deploy-infrastructure) - Create AWS resources (30 min)
5. [Step 3: Deploy Backend](#step-3-deploy-backend) - Setup FastAPI (15 min)
6. [Step 4: Deploy Frontend](#step-4-deploy-frontend) - Deploy React app (10 min)
7. [Verification](#verification) - Make sure everything works
8. [Daily Operations](#daily-operations) - Start, stop, update
9. [Troubleshooting](#troubleshooting) - Fix common issues

**Total Time:** ~2-3 hours | **Cost:** FREE for 12 months

---

## Quick Start

**Check if you're ready to deploy:**

```bash
# 1. AWS CLI installed?
aws --version
# Should show: aws-cli/2.x.x

# 2. AWS CLI configured?
aws sts get-caller-identity
# Should show your account info

# 3. Already deployed?
bash aws/check-resources.sh
# Shows what's running
```

✅ **All working?** Jump to [Step 2](#step-2-deploy-infrastructure)
❌ **Something failed?** Continue with [Prerequisites](#prerequisites)

---

## Prerequisites

### What You're Building

```
User Browser → CloudFront (CDN) → S3 (React Frontend)
                                      ↓
                                 EC2 (FastAPI Backend)
                                      ↓
                                 MongoDB Atlas (Free Database)
```

### What You Need

- [ ] AWS Account ([aws.amazon.com](https://aws.amazon.com))
- [ ] Credit card (for AWS verification - won't be charged in free tier)
- [ ] Computer with terminal access
- [ ] 2-3 hours of time

---

## Step 1: Setup

### 1.1 Create AWS Account

1. Go to [aws.amazon.com](https://aws.amazon.com)
2. Click "Create an AWS Account"
3. Complete signup (email, password, payment method)
4. Verify email and phone

### 1.2 Install AWS CLI

**Windows:**
- Download: [AWSCLIV2.msi](https://awscli.amazonaws.com/AWSCLIV2.msi)
- Run installer

**Mac:**
```bash
brew install awscli
```

**Linux:**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

**Verify:**
```bash
aws --version
```

### 1.3 Create AWS Access Keys

1. Login to [AWS Console](https://console.aws.amazon.com)
2. Click your name (top right) → "Security credentials"
3. Scroll to "Access keys" → "Create access key"
4. Select "Command Line Interface (CLI)"
5. Check confirmation box → "Create access key"
6. **SAVE BOTH:**
   - Access Key ID: `AKIAIOSFODNN7EXAMPLE`
   - Secret Access Key: `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`

### 1.4 Configure AWS CLI

```bash
aws configure
```

Enter:
- **AWS Access Key ID:** [paste your key]
- **AWS Secret Access Key:** [paste your secret]
- **Default region:** `us-east-1`
- **Default output format:** `json`

**Test:**
```bash
aws sts get-caller-identity
# Should show: UserId, Account, Arn
```

### 1.5 Create EC2 Key Pair

**Option A: AWS Console (Easier)**
1. Go to [EC2 Console](https://console.aws.amazon.com/ec2)
2. Left sidebar → "Key Pairs"
3. "Create key pair"
4. Name: `CareFlowAI-Key`
5. Type: RSA, Format: .pem
6. Click "Create" → **Save the .pem file**

**Option B: Command Line**
```bash
aws ec2 create-key-pair \
    --key-name CareFlowAI-Key \
    --query 'KeyMaterial' \
    --output text > CareFlowAI-Key.pem

# Mac/Linux only:
chmod 400 CareFlowAI-Key.pem
```

**Save location:** `C:\Users\YourName\.ssh\CareFlowAI-Key.pem`

### 1.6 Setup MongoDB Atlas (Free Database)

1. Go to [mongodb.com/cloud/atlas](https://www.mongodb.com/cloud/atlas)
2. Sign up (use Google/Email)
3. Create cluster:
   - Tier: **FREE (M0)**
   - Provider: AWS
   - Region: us-east-1
   - Name: CareFlowAI
4. Create user:
   - Username: `careflowai_user`
   - Password: [create strong password - save it!]
5. Network Access:
   - Click "Add IP Address"
   - Click "Allow Access from Anywhere" (we'll restrict this later)
6. Get connection string:
   - Click "Connect" → "Connect your application"
   - Copy string: `mongodb+srv://careflowai_user:<password>@...`
   - Replace `<password>` with your actual password

**✅ Checklist:**
- [ ] AWS CLI installed and configured
- [ ] EC2 key pair created and saved
- [ ] MongoDB Atlas cluster created
- [ ] MongoDB connection string saved

---

## Step 2: Deploy Infrastructure

**What this creates:** VPC, EC2 instance, S3 bucket, CloudFront distribution
**Time:** ~30 minutes
**Cost:** FREE

### 2.1 Edit Configuration

Open: `aws/scripts/deploy-infrastructure.sh`

Change line 13:
```bash
KEY_NAME="CareFlowAI-Key"  # Your key pair name
```

That's it! Just one line.

### 2.2 Run Deployment

```bash
cd "path/to/CareFlowAI"
bash aws/scripts/deploy-infrastructure.sh
```

**What happens:**
```
[1/4] Creating VPC (network)...           ⏱️  2 min
[2/4] Creating Security Groups...         ⏱️  1 min
[3/4] Creating EC2 instance...            ⏱️  3 min
[4/4] Creating S3 & CloudFront...         ⏱️  20 min
```

☕ Good time for a coffee break!

### 2.3 Save Important Info

When complete, you'll see:
```
=========================================
Infrastructure Deployment Complete!
=========================================

VPC ID: vpc-xxxxx
Security Group ID: sg-xxxxx
EC2 Elastic IP: 54.123.45.67          ← SAVE THIS!
S3 Bucket: careflowai-frontend-xxxxx  ← SAVE THIS!
CloudFront Domain: d111111abcdef8.cloudfront.net  ← SAVE THIS!
```

**Write these down:**
- EC2 Elastic IP: `__________________`
- S3 Bucket: `__________________`
- CloudFront Domain: `__________________`

### 2.4 Update MongoDB Access

1. Go to MongoDB Atlas
2. Click "Network Access" (left sidebar)
3. Click "Edit" on the "0.0.0.0/0" entry
4. Delete it
5. Click "Add IP Address"
6. Paste your **EC2 Elastic IP**
7. Click "Confirm"

**✅ Checklist:**
- [ ] Infrastructure deployed successfully
- [ ] Saved EC2 Elastic IP
- [ ] Saved S3 Bucket name
- [ ] Saved CloudFront domain
- [ ] Updated MongoDB network access

---

## Step 2.5: Seed MongoDB Atlas (TESTING ONLY)

**⚠️ FOR TESTING PURPOSES ONLY - NOT FOR PRODUCTION**

This optional step populates your MongoDB Atlas database with sample users and appointments to help you test the application quickly. **Skip this step if you're deploying to production.**

### What This Creates

The seeding script will create:
- **7 test users** (3 patients, 2 doctors, 1 receptionist, 1 admin)
- **9 sample appointments** (scheduled, completed, and cancelled)
- **3 sample comments** on appointments

### Run the Seeding Script

**Using Bash (Mac/Linux/Git Bash on Windows):**

```bash
cd "path/to/CareFlowAI"
bash aws/scripts/deploy-mongodb-mockdata.sh
```

**What the script does:**
1. ✅ Loads MongoDB connection string from `backend/.env`
2. ✅ Warns you that it will DELETE all existing data
3. ✅ Asks for confirmation
4. ✅ Creates/activates Python virtual environment
5. ✅ Installs dependencies
6. ✅ Runs the seeding script
7. ✅ Shows you the test account credentials

### Test Accounts Created

After seeding, you can log in with these accounts:

**📋 PATIENTS:**
- john.doe@example.com / password123
- jane.smith@example.com / password123
- bob.wilson@example.com / password123

**👨‍⚕️ DOCTORS:**
- sarah.johnson@hospital.com / password123
- michael.chen@hospital.com / password123

**📞 RECEPTIONIST:**
- emily.davis@hospital.com / password123

**🔧 ADMIN:**
- admin@hospital.com / admin123

### Important Notes

⚠️ **WARNING:** This script will **DELETE ALL EXISTING DATA** in your MongoDB database and replace it with test data. Only use this for:
- ✅ Testing the application
- ✅ Development environments
- ✅ Demos and presentations
- ❌ **NOT for production deployments**

**✅ Checklist:**
- [ ] Ran seeding script (optional, testing only)
- [ ] Saved test account credentials
- [ ] Ready to proceed with backend deployment

---

## Step 3: Deploy Backend

**What this does:** Installs FastAPI on EC2, configures database, sets up auto-start
**Time:** ~15 minutes
**Cost:** FREE

---

### Option A: Quick Start (Using deploy-backend.sh from Local Machine)

**Perfect for:** Fast deployment, fully automated, uses GitHub repository

**Prerequisites:**
- You've completed Step 2 (Infrastructure deployed)
- You have the EC2 Elastic IP and SSH key
- Your GitHub repository is **public** (or use SSH URL with credentials)
- You're on your local machine in the CareFlowAI directory

#### 1. Configure the Deployment Script

Edit `aws/scripts/deploy-backend.sh` in your local CareFlowAI directory:

```bash
EC2_IP="54.225.66.151"  # Your EC2 Elastic IP from Step 2.3
KEY_FILE="$HOME/.ssh/CareFlowAI-Key-New.pem"  # Path to your SSH key
REPO_URL="https://github.com/YOUR-USERNAME/CareFlowAI.git"  # Your public GitHub repo
MONGODB_URL="mongodb+srv://user:password%40123@cluster.mongodb.net/?retryWrites=true&w=majority"  # MongoDB Atlas (URL-encoded password)
SECRET_KEY="your-jwt-secret-key"  # Generate with: openssl rand -hex 32
GEMINI_API_KEY="your-gemini-api-key"  # Your Google Gemini API key
```

**Important - URL Encoding Passwords:**
Special characters in MongoDB password must be URL-encoded:
- `@` → `%40`
- `#` → `%23`
- `%` → `%25`
- `/` → `%2F`

Example: `MyPass@123` becomes `MyPass%40123`

#### 2. Run the Deployment Script

**On your local machine:**
```bash
cd "path/to/CareFlowAI"

# Make script executable (first time only)
chmod +x aws/scripts/deploy-backend.sh

# Run full deployment
bash aws/scripts/deploy-backend.sh
```

**What this script does (FULLY AUTOMATED):**
1. ✅ Tests SSH connection to EC2
2. ✅ **Automatically fixes SSH key permissions** (Windows/Linux/Mac)
3. ✅ Updates system packages on EC2
4. ✅ Installs dependencies (Python, Nginx, Git)
5. ✅ **Clones repository from GitHub**
6. ✅ Creates Python virtual environment
7. ✅ Installs all Python packages
8. ✅ **Creates .env file** with your credentials
9. ✅ **Initializes database** (if MongoDB accessible)
10. ✅ **Creates admin user** (if database initialized)
11. ✅ **Sets up systemd service** for auto-start
12. ✅ **Configures Nginx** as reverse proxy
13. ✅ **Starts backend service**
14. ✅ **Verifies deployment** with health check

**Time:** ~5-8 minutes ⚡

**No manual steps needed!** The script handles everything automatically.

After the script completes, you'll see a summary with:
- ✅ Backend health check status
- 🌐 Access URLs (API docs, health endpoint)
- 📋 Useful commands

**Test Your Backend:**

Open your browser and visit:
- **API Documentation**: `http://YOUR-ELASTIC-IP/docs`
- **Health Check**: `http://YOUR-ELASTIC-IP/health`

You should see the FastAPI interactive documentation! 🎉

#### 4. If MongoDB Connection Fails

If you see "Database initialization failed" warnings during deployment:

**Cause:** MongoDB Atlas hasn't whitelisted your EC2 IP yet.

**Fix:**
1. Go to [MongoDB Atlas](https://cloud.mongodb.com)
2. Click "Network Access" (left sidebar)
3. Click "Add IP Address"
4. Enter your EC2 IP
5. Click "Confirm"

**Then restart backend:**
```bash
ssh -i ~/.ssh/CareFlowAI-Key-New.pem ubuntu@YOUR-ELASTIC-IP
sudo systemctl restart careflowai-backend
sudo systemctl status careflowai-backend
```

**✅ Checklist:**
- [ ] Edited `aws/scripts/deploy-backend.sh` with your credentials
- [ ] Script automatically fixed SSH key permissions
- [ ] Script ran successfully (5-8 minutes)
- [ ] Backend service is running
- [ ] Can access `http://YOUR-ELASTIC-IP/docs`
- [ ] Added EC2 IP to MongoDB Atlas Network Access
- [ ] Database initialized successfully

---

### Option B: Manual Step-by-Step (AWS Console Only)

**Perfect for:** First-time deployment, learning, detailed control, no local terminal

**Prerequisites:**
- You've completed Step 2 (Infrastructure deployed)
- You have MongoDB connection string ready
- You'll use only AWS Console and browser

#### 1. Connect to EC2 via AWS Console

1. Go to [EC2 Console](https://console.aws.amazon.com/ec2)
2. Click "Instances" in left sidebar
3. Select your CareFlowAI instance (should be running)
4. Click "Connect" button at the top
5. Choose "EC2 Instance Connect" tab
6. Click "Connect" button

A new browser window opens with a terminal! 🎉

#### 2. Install System Dependencies

Copy and paste into the EC2 terminal:

```bash
# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install Python, Nginx, and Git
sudo apt-get install -y python3-pip python3-venv nginx git
```

Wait for installation to complete (~3 minutes).

#### 3. Setup Project Directory

```bash
# Create application directory
sudo mkdir -p /opt/careflowai

# Give ubuntu user ownership
sudo chown ubuntu:ubuntu /opt/careflowai

# Navigate to directory
cd /opt/careflowai
```

#### 4. Upload Backend Code

**Choose one method:**

**Method A: Clone from GitHub (Recommended if you have a repo)**

```bash
# Clone your repository
git clone https://github.com/YOUR-USERNAME/CareFlowAI.git .

# Verify files
ls -la
# Should see: backend/ frontend/ aws/ README.md etc.
```

**Method B: Manual File Upload (If no GitHub repo)**

1. Keep EC2 terminal open
2. On your local machine, compress backend folder:
   - **Windows:** Right-click `backend` folder → Send to → Compressed (zipped) folder
   - **Mac/Linux:** Run `tar -czf backend.tar.gz backend/`
3. In AWS Console, go to **EC2 → Instances** → Select instance
4. Click "Actions" → "Connect" → "Session Manager" → "Connect"
5. Run: `sudo yum install -y ec2-instance-connect`
6. Alternative: Use FileZilla or WinSCP to upload files via SFTP
   - Host: `sftp://YOUR-ELASTIC-IP`
   - Username: `ubuntu`
   - Key file: Your .pem file
   - Upload `backend.tar.gz` to `/opt/careflowai/`

If uploaded compressed file:
```bash
cd /opt/careflowai
tar -xzf backend.tar.gz
rm backend.tar.gz
```

#### 5. Create Python Virtual Environment

```bash
# Navigate to app directory
cd /opt/careflowai

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Your prompt should now show: (venv)

# Upgrade pip
pip install --upgrade pip
```

#### 6. Install Python Dependencies

```bash
# Navigate to backend
cd /opt/careflowai/backend

# Install all required packages
pip install -r requirements.txt
```

Wait for installation (~2-3 minutes).

#### 7. Create Environment Configuration File

```bash
# Create .env file
nano .env
```

**Copy and paste this** (you'll edit values next):

```env
MONGODB_URL=mongodb+srv://careflowai_user:yourpassword@careflowai.xxxxx.mongodb.net/
DATABASE_NAME=careflowai
SECRET_KEY=your-secret-key-here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
UPLOAD_DIR=/opt/careflowai/backend/uploads
MAX_UPLOAD_SIZE=10485760
GEMINI_API_KEY=your-gemini-api-key
```

**Edit the values:**

1. **MONGODB_URL**: Your MongoDB Atlas connection string from Step 1.6
2. **SECRET_KEY**: Generate a secure key by opening a new terminal line (Ctrl+X to exit nano first):
   ```bash
   openssl rand -hex 32
   ```
   Copy the output, then run `nano .env` again and paste it as SECRET_KEY

3. **GEMINI_API_KEY**: Your Google Gemini API key (get from [ai.google.dev](https://ai.google.dev))

**Save the file:**
- Press `Ctrl + X`
- Press `Y` (yes)
- Press `Enter`

#### 8. Initialize Database

```bash
# Create uploads directory
mkdir -p uploads

# Make sure virtual environment is active
source /opt/careflowai/venv/bin/activate

# Initialize database structure
python scripts/init_db.py
```

You should see: "✓ Database initialized successfully"

```bash
# Create admin user
python scripts/add_admin.py
```

You should see: "✓ Admin user created successfully"

**Save admin credentials shown!**

#### 9. Test Backend (Optional)

```bash
# Start backend manually to test
python run.py
```

You should see:
```
INFO:     Uvicorn running on http://0.0.0.0:8000
INFO:     Application startup complete.
```

Press `Ctrl + C` to stop.

#### 10. Create Auto-Start Service

This makes backend start automatically when EC2 restarts.

```bash
sudo nano /etc/systemd/system/careflowai-backend.service
```

**Copy and paste:**

```ini
[Unit]
Description=CareFlowAI Backend
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/careflowai/backend
Environment="PATH=/opt/careflowai/venv/bin"
ExecStart=/opt/careflowai/venv/bin/python run.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Save:** `Ctrl+X` → `Y` → `Enter`

**Enable and start the service:**

```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable service (start on boot)
sudo systemctl enable careflowai-backend

# Start service now
sudo systemctl start careflowai-backend

# Check status
sudo systemctl status careflowai-backend
```

Should show: **Active: active (running)** in green ✅

Press `Q` to exit status view.

#### 11. Setup Nginx Reverse Proxy

Nginx forwards external requests (port 80) to your backend (port 8000).

```bash
sudo nano /etc/nginx/sites-available/careflowai
```

**Copy and paste:**

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

**Save:** `Ctrl+X` → `Y` → `Enter`

**Enable the site:**

```bash
# Create symbolic link to enable site
sudo ln -s /etc/nginx/sites-available/careflowai /etc/nginx/sites-enabled/

# Remove default site
sudo rm -f /etc/nginx/sites-enabled/default

# Test nginx configuration
sudo nginx -t
```

Should show: **syntax is ok** and **test is successful** ✅

```bash
# Restart nginx
sudo systemctl restart nginx

# Check nginx status
sudo systemctl status nginx
```

Should show: **Active: active (running)** ✅

#### 12. Verify Backend is Running

```bash
# Check if backend is responding locally
curl http://localhost:8000/health
```

Should return: `{"status":"healthy"}`

```bash
# Exit EC2 terminal
exit
```

#### 13. Test from Browser

**Open your browser and visit:**

`http://YOUR-ELASTIC-IP/docs`

Replace YOUR-ELASTIC-IP with your actual EC2 Elastic IP from Step 2.3.

You should see:
- **FastAPI interactive documentation** page
- List of all API endpoints
- Ability to test endpoints

🎉 **Success!** Your backend is deployed and running!

**✅ Complete Checklist:**
- [ ] Connected to EC2 via AWS Console
- [ ] Installed system dependencies (Python, Nginx, Git)
- [ ] Created project directory at /opt/careflowai
- [ ] Uploaded/cloned backend code
- [ ] Created Python virtual environment
- [ ] Installed Python dependencies
- [ ] Created and configured .env file with all credentials
- [ ] Generated SECRET_KEY with openssl
- [ ] Initialized database with init_db.py
- [ ] Created admin user with add_admin.py
- [ ] Created systemd service file
- [ ] Started and enabled careflowai-backend service
- [ ] Configured Nginx reverse proxy
- [ ] Verified backend responds to curl
- [ ] Can access http://YOUR-ELASTIC-IP/docs in browser

**Troubleshooting:**

If you can't access the backend:

```bash
# Reconnect to EC2
# Go to EC2 Console → Instances → Select instance → Connect → EC2 Instance Connect

# Check backend service
sudo systemctl status careflowai-backend

# View backend logs
sudo journalctl -u careflowai-backend -n 50

# Check nginx
sudo systemctl status nginx

# Check if port 8000 is listening
sudo netstat -tlnp | grep 8000
```

---

## Step 4: Deploy Frontend

**What this does:** Builds React app and uploads to S3/CloudFront
**Time:** ~10 minutes
**Cost:** FREE

### 4.1 Get CloudFront Distribution ID

1. Go to [CloudFront Console](https://console.aws.amazon.com/cloudfront)
2. Find your distribution
3. Copy the ID (starts with `E`, like `E1234567890ABC`)

### 4.2 Edit Deployment Script

Open: `aws/scripts/deploy-frontend.sh`

Change these lines:
```bash
S3_BUCKET="careflowai-frontend-xxxxx"      # From Step 2.3
CLOUDFRONT_DISTRIBUTION_ID="E1234567890ABC" # From Step 4.1
API_URL="http://54.123.45.67"              # Your Elastic IP
```

### 4.3 Deploy

```bash
cd "path/to/CareFlowAI"
bash aws/scripts/deploy-frontend.sh
```

**What happens:**
```
[1/4] Installing dependencies...
[2/4] Building production bundle...
[3/4] Uploading to S3...
[4/4] Invalidating CloudFront cache...
```

### 4.4 Access Application

**Wait 2-3 minutes** for CloudFront to update.

**Open browser:** `https://YOUR-CLOUDFRONT-DOMAIN.cloudfront.net`

You should see the login page! 🎉

**✅ Checklist:**
- [ ] Got CloudFront distribution ID
- [ ] Edited deploy script
- [ ] Deployed successfully
- [ ] Can access frontend
- [ ] Frontend connects to backend

---

## Verification

### ✅ Final Checklist

**Infrastructure:**
```bash
bash aws/check-resources.sh
```
Should show:
- ✅ EC2 instance running
- ✅ S3 bucket exists
- ✅ CloudFront active

**Backend:**
- ✅ http://YOUR-IP/docs shows API docs
- ✅ http://YOUR-IP/health returns {"status":"healthy"}

**Frontend:**
- ✅ https://YOUR-CLOUDFRONT-DOMAIN shows login
- ✅ Can login with admin credentials
- ✅ Can create/view appointments

**Test Flow:**
1. Open frontend URL
2. Login with admin user
3. Create a test appointment
4. View appointments list
5. All features working ✅

---

## Daily Operations

### Check Status

```bash
bash aws/check-resources.sh
```

### Start Stopped Resources

```bash
bash aws/startup-aws-resources.sh
```

### Stop Resources (Save Money)

```bash
# Get instance ID
INSTANCE_ID=$(aws cloudformation describe-stacks \
    --stack-name CareFlowAI-Backend \
    --query 'Stacks[0].Outputs[?OutputKey==`InstanceId`].OutputValue' \
    --output text)

# Stop instance
aws ec2 stop-instances --instance-ids $INSTANCE_ID
```

### View Backend Logs

```bash
ssh -i your-key.pem ubuntu@YOUR-IP
sudo journalctl -u careflowai-backend -f
```

### Restart Backend

```bash
ssh -i your-key.pem ubuntu@YOUR-IP
sudo systemctl restart careflowai-backend
```

### Update Backend Code

```bash
ssh -i your-key.pem ubuntu@YOUR-IP
cd /opt/careflowai
git pull origin main
cd backend
source venv/bin/activate
pip install -r requirements.txt
sudo systemctl restart careflowai-backend
```

### Update Frontend

```bash
bash aws/scripts/deploy-frontend.sh
# Wait 2-3 minutes for CloudFront
```

---

## Troubleshooting

### Can't SSH into EC2

**Check instance is running:**
```bash
aws ec2 describe-instances \
    --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' \
    --output table
```

**Start if stopped:**
```bash
aws ec2 start-instances --instance-ids i-xxxxx
```

**Check security group:**
- EC2 Console → Security Groups
- Inbound rules should allow SSH (port 22) from your IP

### Backend Not Responding

**Check service status:**
```bash
ssh -i your-key.pem ubuntu@YOUR-IP
sudo systemctl status careflowai-backend
```

**View logs:**
```bash
sudo journalctl -u careflowai-backend -n 100
```

**Restart service:**
```bash
sudo systemctl restart careflowai-backend
```

### Can't Connect to MongoDB

**Test connection:**
```bash
ssh -i your-key.pem ubuntu@YOUR-IP
cd /opt/careflowai/backend
source venv/bin/activate
python3 -c "from pymongo import MongoClient; client = MongoClient('YOUR-CONNECTION-STRING'); print(client.server_info())"
```

**Check MongoDB Atlas:**
1. Network Access includes EC2 IP
2. Database user exists
3. Connection string is correct in .env

### Frontend Shows Old Version

**Clear CloudFront cache:**
```bash
aws cloudfront create-invalidation \
    --distribution-id YOUR-DISTRIBUTION-ID \
    --paths "/*"
```

**Clear browser cache:**
- Chrome: Ctrl+Shift+Delete
- Firefox: Ctrl+Shift+Delete
- Safari: Cmd+Option+E

### Permission Denied (.pem file)

**Mac/Linux:**
```bash
chmod 400 your-key.pem
```

**Windows:**
- Right-click .pem file → Properties → Security → Advanced
- Click "Disable inheritance"
- Remove all users except yourself
- Give yourself Full Control

---

## Cost Information

### Free Tier (First 12 Months)
- EC2 t2.micro: FREE (750 hours/month)
- S3: FREE (5GB storage, 20,000 GET requests)
- CloudFront: FREE (1TB transfer, 10M requests)
- MongoDB Atlas M0: FREE (forever!)

**Total: $0/month**

### After Free Tier
- EC2 t2.micro: ~$8-10/month
- S3 + CloudFront: ~$1-3/month
- MongoDB Atlas M0: FREE

**Total: ~$10-15/month**

### Save Money

**When not using:**
```bash
# Stop EC2 instance
aws ec2 stop-instances --instance-ids i-xxxxx
```

**When needed again:**
```bash
bash aws/startup-aws-resources.sh
```

---

## Delete Everything

**WARNING:** This deletes ALL resources and CANNOT be undone!

```bash
bash aws/cleanup-aws-resources.sh
```

Or manually:
```bash
# Delete CloudFormation stacks
aws cloudformation delete-stack --stack-name CareFlowAI-Frontend
aws cloudformation delete-stack --stack-name CareFlowAI-Backend
aws cloudformation delete-stack --stack-name CareFlowAI-SecurityGroups
aws cloudformation delete-stack --stack-name CareFlowAI-VPC
```

---

## Quick Command Reference

```bash
# Check everything
bash aws/check-resources.sh

# Start resources
bash aws/startup-aws-resources.sh

# SSH into server
ssh -i your-key.pem ubuntu@YOUR-IP

# View logs
sudo journalctl -u careflowai-backend -f

# Restart backend
sudo systemctl restart careflowai-backend

# Redeploy frontend
bash aws/scripts/deploy-frontend.sh
```

---

## Next Steps

Once deployed:
1. ✅ Change admin password
2. ✅ Add custom domain (optional)
3. ✅ Enable HTTPS with SSL (optional)
4. ✅ Setup CloudWatch monitoring (optional)
5. ✅ Create backups (optional)

---

## Need More Help?

- **Architecture:** See `AWS_ARCHITECTURE_GUIDE.md`
- **Alternative deployment:** See `DOCKER_KUBERNETES_SETUP.md`
- **AI features:** See `AI_SERVICES_OVERVIEW.md`

---

**Congratulations! Your CareFlowAI application is live on AWS!** 🎉
