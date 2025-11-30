# CareFlowAI AWS Deployment Guide - Step by Step

**Complete walkthrough for deploying CareFlowAI to AWS from start to finish**

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [AWS Account Setup](#aws-account-setup)
3. [MongoDB Atlas Setup](#mongodb-atlas-setup)
4. [Local Environment Setup](#local-environment-setup)
5. [Deploy AWS Infrastructure](#deploy-aws-infrastructure)
6. [Configure EC2 Instance](#configure-ec2-instance)
7. [Deploy Backend Application](#deploy-backend-application)
8. [Deploy Frontend Application](#deploy-frontend-application)
9. [Setup Nginx (Optional)](#setup-nginx-optional)
10. [Configure SSL/HTTPS (Optional)](#configure-ssl-https-optional)
11. [Testing and Verification](#testing-and-verification)
12. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before starting, ensure you have (Skip if you already have them):

- [NO] AWS Account (we'll create this)
- [NO] MongoDB Atlas Account (we'll create this)
- [YES] Git installed on your computer
- [YES] Node.js and npm installed
- [YES] Python 3.8+ installed
- [NO] AWS CLI installed (we'll install this)

---

## AWS Account Setup

### Step 1: Create AWS Account

1. **Go to AWS Website:**
   - Open browser and visit: https://aws.amazon.com
   - Click "Create an AWS Account" button (top right)

2. **Fill Account Details:**
   ```
   Root user email address: your-email@example.com
   AWS account name: CareFlowAI (or your preferred name)
   ```
   - Click "Verify email address"
   - Check your email for verification code
   - Enter the 6-digit code

3. **Create Password:**
   ```
   Password: (create a strong password)
   Confirm password: (re-enter password)
   ```
   - Click "Continue"

4. **Contact Information:**
   ```
   Account type: Personal (or Business if applicable)
   Full name: Your Name
   Phone number: Your phone number
   Country/Region: Your country
   Address: Your address
   City: Your city
   State/Province: Your state
   Postal code: Your postal code
   ```
   - Check the AWS Customer Agreement box
   - Click "Continue"

5. **Payment Information:**
   - Enter credit/debit card details
   - Click "Verify and Continue"
   - AWS will charge $1 for verification (refunded later)

6. **Identity Verification:**
   - Choose verification method (SMS or Voice call)
   - Enter phone number
   - Enter the 4-digit code received
   - Click "Continue"

7. **Select Support Plan:**
   - Select "Basic support - Free"
   - Click "Complete sign up"

8. **Wait for Account Activation:**
   - Account activation can take up to 24 hours
   - You'll receive email when ready
   - Usually takes 5-10 minutes

### Step 2: Create IAM User (For AWS CLI)

1. **Sign in to AWS Console:**
   - Go to: https://console.aws.amazon.com
   - Email: your-root-email@example.com
   - Password: your-root-password
   - Click "Sign in"

2. **Navigate to IAM:**
   - In search bar at top, type "IAM"
   - Click "IAM" from results
   - Or direct link: https://console.aws.amazon.com/iam

3. **Create New User:**
   - Click "Users" in left sidebar
   - Click "Create user" button (top right)

4. **User Details:**
   ```
   User name: careflowai-admin
   ```
   - Check "Provide user access to the AWS Management Console - optional"
   - Select "I want to create an IAM user"
   - Console password: Custom password
   - Enter password: (create a password)
   - Uncheck "Users must create a new password at next sign-in"
   - Click "Next"

5. **Set Permissions:**
   - Select "Attach policies directly"
   - Search and check these policies:
     - [YES] AdministratorAccess (for simplicity - restrict in production)
   - Alternatively, select these individual policies:
     - [YES] AmazonEC2FullAccess
     - [YES] AmazonS3FullAccess
     - [YES] CloudFrontFullAccess
     - [YES] IAMFullAccess
     - [YES] AWSCloudFormationFullAccess
   - Click "Next"

6. **Review and Create:**
   - Review the details
   - Click "Create user"

7. **Save Credentials:**
   - Click "Download .csv" button
   - Save file to secure location
   - This contains console sign-in URL and credentials
   - Click "Return to users list"

### Step 3: Create Access Keys (For AWS CLI)

1. **Select User:**
   - Click on "careflowai-admin" user you just created

2. **Create Access Key:**
   - Click "Security credentials" tab
   - Scroll down to "Access keys" section
   - Click "Create access key"

3. **Select Use Case:**
   - Select "Command Line Interface (CLI)"
   - Check "I understand the above recommendation..."
   - Click "Next"

4. **Set Description (Optional):**
   ```
   Description tag: CareFlowAI Deployment
   ```
   - Click "Create access key"

5. **Download Access Key:**
   - You'll see:
     ```
     Access key: AKIAIOSFODNN7EXAMPLE (example)
     Secret access key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY (example)
     ```
   - Click "Download .csv file"
   - Save to secure location (you'll need these values)
   - [IMPORTANT] This is the ONLY time you can view the secret key
   - Click "Done"

### Step 4: Create EC2 Key Pair

1. **Navigate to EC2:**
   - In search bar, type "EC2"
   - Click "EC2" from results
   - Or go to: https://console.aws.amazon.com/ec2

2. **Select Region:**
   - Top right corner, click region dropdown
   - Select "US East (N. Virginia) us-east-1"
   - [IMPORTANT] Remember this region - use same everywhere

3. **Create Key Pair:**
   - Left sidebar, scroll down to "Network & Security"
   - Click "Key Pairs"
   - Click "Create key pair" button (top right)

4. **Key Pair Details:**
   ```
   Name: careflowai-key
   Key pair type: RSA
   Private key file format: .pem (for Mac/Linux) or .ppk (for Windows/PuTTY)
   ```
   - Click "Create key pair"

5. **Save Key File:**
   - File will automatically download: `careflowai-key.pem`
   - Move to secure location:

   **On Mac/Linux:**
   ```bash
   mkdir -p ~/.ssh
   mv ~/Downloads/careflowai-key.pem ~/.ssh/
   chmod 400 ~/.ssh/careflowai-key.pem
   ```

   **On Windows:**
   ```powershell
   # Create .ssh directory in user home
   mkdir $HOME\.ssh
   # Move key file
   move $HOME\Downloads\careflowai-key.pem $HOME\.ssh\
   ```

---

## MongoDB Atlas Setup

### Step 1: Create MongoDB Atlas Account

1. **Visit MongoDB Atlas:**
   - Go to: https://www.mongodb.com/cloud/atlas/register
   - Or click "Try Free" at: https://www.mongodb.com

2. **Sign Up:**
   - You can sign up with:
     - Google account (easiest)
     - Email and password

   **If using email:**
   ```
   Email: your-email@example.com
   Password: (create strong password)
   First name: Your first name
   Last name: Your last name
   ```
   - Check "I agree to MongoDB's Privacy Policy and Terms of Service"
   - Click "Create your Atlas account"

3. **Verify Email:**
   - Check your email
   - Click verification link
   - You'll be redirected to Atlas

4. **Welcome Questions (Optional):**
   - You may see questionnaire about your use case
   - You can skip or answer:
     ```
     What is your goal? Building a new application
     What kind of application? Healthcare application
     Programming language: Python
     ```
   - Click "Finish"

### Step 2: Create Free Cluster

1. **Deploy a Database:**
   - Click "Build a Database" button
   - Or if you see "Create" button, click it

2. **Choose Deployment Option:**
   - Select "M0 FREE" (left option)
   - Configuration:
     ```
     Provider: AWS
     Region: us-east-1 (N. Virginia) - [IMPORTANT] Same as EC2
     Cluster Name: careflowai-cluster (or keep default)
     ```
   - Click "Create Deployment" or "Create Cluster"

3. **Security Quick Start - Create User:**
   - You'll see "Create Database User" dialog
   ```
   Authentication Method: Password
   Username: careflowai_admin
   Password: Click "Autogenerate Secure Password"
   ```
   - [IMPORTANT] Copy the password immediately and save it
   - Or create your own strong password
   - Click "Create Database User"

4. **Security Quick Start - Network Access:**
   - You'll see "Where would you like to connect from?"
   - For now, select "My Local Environment"
   - Click "Add My Current IP Address"
   - Or manually add: `0.0.0.0/0` (allow from anywhere - temporary)
   - Click "Add Entry"
   - Click "Finish and Close"

5. **Wait for Cluster:**
   - Cluster creation takes 3-5 minutes
   - You'll see "Cluster is being created" message
   - Wait until status shows "Active" with green checkmark

### Step 3: Get Connection String

1. **Click Connect:**
   - On your cluster, click "Connect" button

2. **Choose Connection Method:**
   - Click "Drivers"

3. **Select Driver and Version:**
   ```
   Driver: Python
   Version: 3.12 or later
   ```

4. **Copy Connection String:**
   - You'll see connection string like:
   ```
   mongodb+srv://careflowai_admin:<password>@careflowai-cluster.xxxxx.mongodb.net/?retryWrites=true&w=majority
   ```
   - Click "Copy" button
   - Paste into text editor

5. **Replace Password Placeholder:**
   - Find `<password>` in the string
   - Replace with your actual password (from Step 2.3)
   - Final string should look like:
   ```
   mongodb+srv://careflowai_admin:YourActualPassword123@careflowai-cluster.xxxxx.mongodb.net/?retryWrites=true&w=majority
   ```
   - Save this string - you'll need it later

### Step 4: Configure Network Access (Will Update Later)

- We'll update this to EC2's IP after deployment
- For now, leave it as `0.0.0.0/0`

---

## Local Environment Setup

### Step 1: Install AWS CLI

**On Windows:**

1. **Download AWS CLI:**
   - Go to: https://awscli.amazonaws.com/AWSCLIV2.msi
   - Run the downloaded .msi file
   - Follow installation wizard
   - Click "Next" → "Next" → "Install"

2. **Verify Installation:**
   ```powershell
   # Open PowerShell
   aws --version
   ```
   - Should show: `aws-cli/2.x.x Python/3.x.x Windows/...`

**On Mac:**

1. **Install using Homebrew:**
   ```bash
   # If you don't have Homebrew, install it first
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

   # Install AWS CLI
   brew install awscli
   ```

2. **Verify Installation:**
   ```bash
   aws --version
   ```

**On Linux (Ubuntu):**

1. **Install AWS CLI:**
   ```bash
   sudo apt-get update
   sudo apt-get install -y awscli

   # Or use the official installer
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   ```

2. **Verify Installation:**
   ```bash
   aws --version
   ```

### Step 2: Configure AWS CLI

1. **Run Configuration:**
   ```bash
   aws configure
   ```

2. **Enter Your Credentials:**
   - You'll be prompted for 4 pieces of information
   - Get these from the .csv file you downloaded earlier

   ```
   AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
   ```
   - Press Enter

   ```
   AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
   ```
   - Press Enter

   ```
   Default region name [None]: us-east-1
   ```
   - Press Enter

   ```
   Default output format [None]: json
   ```
   - Press Enter

3. **Verify Configuration:**
   ```bash
   # Test AWS CLI
   aws sts get-caller-identity
   ```
   - You should see output like:
   ```json
   {
       "UserId": "AIDAI...",
       "Account": "123456789012",
       "Arn": "arn:aws:iam::123456789012:user/careflowai-admin"
   }
   ```

### Step 3: Clone Repository (If Not Already)

1. **Navigate to Projects Directory:**
   ```bash
   # Windows
   cd C:\Users\YourName\Projects

   # Mac/Linux
   cd ~/Projects
   ```

2. **If You Need to Clone:**
   ```bash
   git clone https://github.com/your-username/CareFlowAI.git
   cd CareFlowAI
   ```

3. **Or Navigate to Existing:**
   ```bash
   cd path/to/CareFlowAI
   ```

### Step 4: Make Scripts Executable

**On Mac/Linux:**
```bash
cd aws/scripts
chmod +x *.sh
cd ../..
```

**On Windows:**
- Scripts can be run with: `bash script-name.sh`
- Or use Git Bash

---

## Deploy AWS Infrastructure

### Step 1: Configure Infrastructure Script

1. **Open Infrastructure Script:**
   ```bash
   # Open in your preferred editor
   # Windows
   notepad aws/scripts/deploy-infrastructure.sh

   # Mac
   nano aws/scripts/deploy-infrastructure.sh

   # Or use VS Code
   code aws/scripts/deploy-infrastructure.sh
   ```

2. **Update Configuration (Line 13-16):**
   ```bash
   # Find these lines and update:
   STACK_NAME_PREFIX="CareFlowAI"           # Keep as is
   REGION="us-east-1"                        # Keep as is
   KEY_NAME="careflowai-key"                 # Your EC2 key pair name
   INSTANCE_TYPE="t2.micro"                  # Keep as is (or t3.small)
   ```

3. **Save the File:**
   - In nano: Ctrl+X, then Y, then Enter
   - In notepad: File → Save
   - In VS Code: Ctrl+S (Windows/Linux) or Cmd+S (Mac)

### Step 2: Run Infrastructure Deployment

1. **Execute the Script:**
   ```bash
   # Make sure you're in project root
   cd CareFlowAI

   # Run the script
   bash aws/scripts/deploy-infrastructure.sh

   # Or if executable
   ./aws/scripts/deploy-infrastructure.sh
   ```

2. **What Happens:**
   - Script creates VPC (takes 2-3 minutes)
   - Script creates Security Groups (takes 1-2 minutes)
   - Script creates EC2 instance (takes 3-5 minutes)
   - Script creates S3 and CloudFront (takes 5-10 minutes)
   - Total time: 10-20 minutes

3. **Watch the Output:**
   ```
   Starting CareFlowAI infrastructure deployment...
   Deploying VPC...
   Waiting for stack CareFlowAI-VPC to complete...
   Stack CareFlowAI-VPC created successfully!
   VPC ID: vpc-0abcd1234efgh5678

   Deploying Security Groups...
   ...
   ```

4. **Save the Final Output:**
   - At the end, you'll see a summary like:
   ```
   =========================================
   Infrastructure Deployment Complete!
   =========================================

   Resource Summary:
   VPC ID: vpc-0abcd1234efgh5678
   Security Group ID: sg-0abcd1234efgh5678
   EC2 Elastic IP: 54.123.45.67
   S3 Bucket: careflowai-frontend-123456789012
   CloudFront Domain: d1234567890abc.cloudfront.net

   Next Steps:
   1. SSH into EC2: ssh -i your-key.pem ubuntu@54.123.45.67
   2. Deploy backend application
   3. Deploy frontend to S3
   4. Configure MongoDB Atlas and add Elastic IP to whitelist
   =========================================
   ```

5. **Copy Important Values:**
   - Open a text file and save:
   ```
   EC2 Elastic IP: 54.123.45.67
   S3 Bucket: careflowai-frontend-123456789012
   CloudFront Domain: d1234567890abc.cloudfront.net
   CloudFront Distribution ID: (we'll get this next)
   ```

### Step 3: Get CloudFront Distribution ID

```bash
# Get distribution ID
aws cloudfront list-distributions \
    --query 'DistributionList.Items[*].[Id,DomainName]' \
    --output table
```

Output:
```
---------------------------------------------------
|           ListDistributions                     |
+------------------+------------------------------+
|  E1234567890ABC  |  d1234567890abc.cloudfront.net |
+------------------+------------------------------+
```

Save the ID: `E1234567890ABC`

### Step 4: Update MongoDB Atlas Network Access

1. **Go to MongoDB Atlas:**
   - Visit: https://cloud.mongodb.com
   - Sign in

2. **Navigate to Network Access:**
   - Left sidebar → "Network Access"
   - You should see `0.0.0.0/0` entry

3. **Add EC2 IP:**
   - Click "Add IP Address" button
   - Select "Add Current IP Address" is NOT what we want
   - Select "Add an IP Address"
   ```
   IP Address: 54.123.45.67/32
   Comment: CareFlowAI EC2 Instance
   ```
   - Click "Confirm"

4. **Remove 0.0.0.0/0 (Optional but Recommended):**
   - Find the `0.0.0.0/0` entry
   - Click "Delete" button
   - Click "Confirm"

---

## Configure EC2 Instance

### Step 1: SSH into EC2

1. **Test SSH Connection:**

   **On Mac/Linux:**
   ```bash
   ssh -i ~/.ssh/careflowai-key.pem ubuntu@54.123.45.67
   ```

   **On Windows (using Git Bash or WSL):**
   ```bash
   ssh -i $HOME/.ssh/careflowai-key.pem ubuntu@54.123.45.67
   ```

   **On Windows (using PowerShell with OpenSSH):**
   ```powershell
   ssh -i $HOME\.ssh\careflowai-key.pem ubuntu@54.123.45.67
   ```

2. **First-Time Connection:**
   - You'll see:
   ```
   The authenticity of host '54.123.45.67' can't be established.
   ECDSA key fingerprint is SHA256:...
   Are you sure you want to continue connecting (yes/no)?
   ```
   - Type: `yes` and press Enter

3. **You're In!**
   - You should see Ubuntu welcome message:
   ```
   Welcome to Ubuntu 22.04.x LTS
   ...
   ubuntu@ip-10-0-1-123:~$
   ```

### Step 2: Initial Server Setup

1. **Update System:**
   ```bash
   sudo apt-get update
   sudo apt-get upgrade -y
   ```
   - This takes 2-5 minutes

2. **Verify Installed Software:**
   ```bash
   # Check Python
   python3 --version
   # Should show: Python 3.10.x or higher

   # Check Git
   git --version
   # Should show: git version 2.x.x

   # Check Nginx
   nginx -v
   # Should show: nginx version: nginx/1.x.x
   ```

3. **Exit SSH:**
   ```bash
   exit
   ```

---

## Deploy Backend Application

### Step 1: Generate JWT Secret Key

1. **On Your Local Machine:**
   ```bash
   # Generate random secret key
   openssl rand -hex 32
   ```

2. **Save the Output:**
   - You'll get something like:
   ```
   a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2
   ```
   - Copy this - you'll need it in next step

### Step 2: Configure Backend Deployment Script

1. **Open Backend Script:**
   ```bash
   code aws/scripts/deploy-backend.sh
   # Or
   nano aws/scripts/deploy-backend.sh
   ```

2. **Update Configuration (Lines 9-13):**
   ```bash
   # Set your values:
   EC2_IP="54.123.45.67"  # Your EC2 Elastic IP
   KEY_FILE="$HOME/.ssh/careflowai-key.pem"  # Path to your .pem file
   REPO_URL="https://github.com/your-username/CareFlowAI.git"  # Your repo
   MONGODB_URL="mongodb+srv://careflowai_admin:YourPassword@careflowai-cluster.xxxxx.mongodb.net/?retryWrites=true&w=majority"  # Your MongoDB URL
   SECRET_KEY="a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2"  # From Step 1
   ```

3. **Save the File**

### Step 3: Run Backend Deployment

1. **Execute Script:**
   ```bash
   bash aws/scripts/deploy-backend.sh
   ```

2. **What Happens:**
   - Script connects to EC2 via SSH
   - Clones your repository to `/opt/careflowai`
   - Creates Python virtual environment
   - Installs all dependencies
   - Creates `.env` file with your configuration
   - Creates systemd service
   - Starts backend service

3. **Watch for Success:**
   - Last line should show:
   ```
   Backend deployment completed!
   Test backend: curl http://54.123.45.67:8000/health
   ```

4. **If Script Fails:**
   - Check error message
   - Common issues:
     - Wrong KEY_FILE path → Update path
     - Wrong EC2_IP → Check IP address
     - Repository not accessible → Make repo public or add SSH key

### Step 4: Verify Backend

1. **Test Health Endpoint:**
   ```bash
   curl http://54.123.45.67:8000/health
   ```

   Expected output:
   ```json
   {"status":"healthy","service":"CareFlowAI API","database":"MongoDB"}
   ```

2. **Test API Documentation:**
   - Open browser: `http://54.123.45.67:8000/docs`
   - You should see FastAPI Swagger UI

3. **Check Backend Service:**
   ```bash
   # SSH into EC2
   ssh -i ~/.ssh/careflowai-key.pem ubuntu@54.123.45.67

   # Check service status
   sudo systemctl status careflowai-backend

   # Should show:
   # Active: active (running)

   # View logs
   sudo journalctl -u careflowai-backend -n 50

   # Exit
   exit
   ```

### Step 5: Initialize Database

1. **SSH into EC2:**
   ```bash
   ssh -i ~/.ssh/careflowai-key.pem ubuntu@54.123.45.67
   ```

2. **Navigate to Backend:**
   ```bash
   cd /opt/careflowai/backend
   source venv/bin/activate
   ```

3. **Run Initialization Scripts:**
   ```bash
   # Initialize database (if you have this script)
   python scripts/init_db.py

   # Create admin user (if you have this script)
   python scripts/add_admin.py

   # Seed sample data (optional)
   python scripts/seed_appointments.py
   ```

4. **Exit:**
   ```bash
   deactivate
   exit
   ```

---

## Deploy Frontend Application

### Step 1: Configure Frontend Script

1. **Open Frontend Script:**
   ```bash
   code aws/scripts/deploy-frontend.sh
   # Or
   nano aws/scripts/deploy-frontend.sh
   ```

2. **Update Configuration (Lines 9-12):**
   ```bash
   S3_BUCKET="careflowai-frontend-123456789012"  # From infrastructure output
   CLOUDFRONT_DISTRIBUTION_ID="E1234567890ABC"   # From Step 3 of infrastructure
   API_URL="http://54.123.45.67"                  # Your EC2 Elastic IP
   REGION="us-east-1"                             # Keep as is
   ```

3. **Save the File**

### Step 2: Run Frontend Deployment

1. **Execute Script:**
   ```bash
   # Make sure you're in project root
   cd CareFlowAI

   bash aws/scripts/deploy-frontend.sh
   ```

2. **What Happens:**
   - Creates `.env.production` with API_URL
   - Runs `npm install` (takes 2-5 minutes)
   - Runs `npm run build` (takes 1-3 minutes)
   - Uploads build files to S3
   - Invalidates CloudFront cache (takes 5-10 minutes to propagate)

3. **Watch for Success:**
   ```
   Frontend deployment completed!
   Access your application at:
   S3: http://careflowai-frontend-123456789012.s3-website-us-east-1.amazonaws.com
   CloudFront: https://d1234567890abc.cloudfront.net
   ```

### Step 3: Verify Frontend

1. **Test S3 Website:**
   - Open browser
   - Go to: `http://careflowai-frontend-123456789012.s3-website-us-east-1.amazonaws.com`
   - You should see CareFlowAI login page

2. **Test CloudFront (Recommended):**
   - Open browser
   - Go to: `https://d1234567890abc.cloudfront.net`
   - You should see CareFlowAI login page (with HTTPS!)

3. **Test Complete Flow:**
   - Try to login
   - Navigate between pages
   - Check browser console (F12) for errors

---

## Setup Nginx (Optional)

This step is optional but recommended for production.

### Step 1: SSH into EC2

```bash
ssh -i ~/.ssh/careflowai-key.pem ubuntu@54.123.45.67
```

### Step 2: Copy Nginx Configuration

```bash
# Copy nginx config
sudo cp /opt/careflowai/aws/nginx/careflowai.conf /etc/nginx/sites-available/careflowai

# Enable site
sudo ln -s /etc/nginx/sites-available/careflowai /etc/nginx/sites-enabled/careflowai

# Remove default site
sudo rm /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t
```

Expected output:
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

### Step 3: Restart Nginx

```bash
sudo systemctl restart nginx
sudo systemctl enable nginx
```

### Step 4: Update Security Group (Remove Port 8000)

Now that Nginx is routing traffic, remove direct access to port 8000:

1. **Go to AWS Console:**
   - Navigate to EC2 → Security Groups
   - Find "CareFlowAI-Backend-SG"
   - Click on it

2. **Edit Inbound Rules:**
   - Click "Edit inbound rules"
   - Find the rule for port 8000
   - Click "Delete" (X button)
   - Click "Save rules"

3. **Test:**
   ```bash
   # This should now work through Nginx on port 80
   curl http://54.123.45.67/health

   # This should NOT work (port 8000 is blocked)
   curl http://54.123.45.67:8000/health
   ```

### Step 5: Update Frontend API URL

If you setup Nginx, update frontend to use port 80:

1. **Edit Frontend Script:**
   ```bash
   nano aws/scripts/deploy-frontend.sh
   ```

2. **Change API_URL:**
   ```bash
   API_URL="http://54.123.45.67"  # Remove :8000
   ```

3. **Redeploy Frontend:**
   ```bash
   bash aws/scripts/deploy-frontend.sh
   ```

### Step 6: Exit SSH

```bash
exit
```

---

## Configure SSL/HTTPS (Optional)

This section is for adding a custom domain with SSL certificate.

### Option A: Using CloudFront (Free SSL)

CloudFront already provides HTTPS! Just use the CloudFront URL:
```
https://d1234567890abc.cloudfront.net
```

No additional setup needed!

### Option B: Custom Domain with Route 53

If you want a custom domain like `careflow.yourdomain.com`:

1. **Purchase Domain:**
   - AWS Route 53: https://console.aws.amazon.com/route53
   - Click "Register domain"
   - Follow steps to purchase (costs vary)

2. **Request SSL Certificate:**
   - Go to: https://console.aws.amazon.com/acm
   - Click "Request certificate"
   - Certificate type: Public certificate
   - Domain names: `yourdomain.com` and `*.yourdomain.com`
   - Validation method: DNS validation
   - Click "Request"

3. **Validate Certificate:**
   - Follow DNS validation instructions
   - Add CNAME records to Route 53
   - Wait for validation (5-30 minutes)

4. **Update CloudFront:**
   - Go to CloudFront console
   - Select your distribution
   - Click "Edit"
   - Alternate domain names: `careflow.yourdomain.com`
   - Custom SSL certificate: Select your certificate
   - Click "Save changes"

5. **Create DNS Record:**
   - Route 53 → Hosted zones
   - Select your domain
   - Create record:
     - Name: `careflow`
     - Type: A
     - Alias: Yes
     - Alias target: CloudFront distribution
     - Click "Create"

6. **Update Frontend:**
   - Change API_URL in deploy-frontend.sh
   - Redeploy frontend

---

## Testing and Verification

### Full Application Test

1. **Access Frontend:**
   - Open: `https://d1234567890abc.cloudfront.net`
   - Or your custom domain if configured

2. **Test Login:**
   - If you created admin user:
   ```
   Username: admin
   Password: (your admin password)
   ```
   - Click "Login"

3. **Test Navigation:**
   - Dashboard
   - Appointments
   - Schedule
   - Each page should load without errors

4. **Test API Calls:**
   - Open browser console (F12)
   - Go to Network tab
   - Perform actions (login, load data)
   - Check for successful API calls (status 200)

5. **Test Backend Directly:**
   ```bash
   # Health check
   curl http://54.123.45.67/health

   # API docs
   curl http://54.123.45.67/docs
   ```

### Check All Services

1. **EC2 Backend:**
   ```bash
   ssh -i ~/.ssh/careflowai-key.pem ubuntu@54.123.45.67
   sudo systemctl status careflowai-backend
   exit
   ```

2. **S3 Frontend:**
   ```bash
   aws s3 ls s3://careflowai-frontend-123456789012/
   ```

3. **CloudFront:**
   ```bash
   aws cloudfront get-distribution --id E1234567890ABC
   ```

4. **MongoDB:**
   - Go to MongoDB Atlas
   - Database → Browse Collections
   - Check if data exists

---

## Troubleshooting

### Backend Issues

**Backend service not starting:**
```bash
# SSH into EC2
ssh -i ~/.ssh/careflowai-key.pem ubuntu@54.123.45.67

# Check service status
sudo systemctl status careflowai-backend

# Check logs
sudo journalctl -u careflowai-backend -n 100 --no-pager

# Common issues:
# 1. MongoDB connection failed
#    - Check MONGODB_URL in /opt/careflowai/backend/.env
#    - Verify EC2 IP is whitelisted in MongoDB Atlas

# 2. Module not found
#    - cd /opt/careflowai/backend
#    - source venv/bin/activate
#    - pip install -r requirements.txt
#    - sudo systemctl restart careflowai-backend

# 3. Port already in use
#    - sudo netstat -tlnp | grep 8000
#    - Kill process or use different port

# Restart service
sudo systemctl restart careflowai-backend
```

**Can't SSH into EC2:**
```bash
# 1. Check key file permissions
ls -l ~/.ssh/careflowai-key.pem
# Should be: -r-------- (400)

# Fix if needed
chmod 400 ~/.ssh/careflowai-key.pem

# 2. Check EC2 is running
aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=CareFlowAI-Backend" \
    --query 'Reservations[*].Instances[*].[State.Name]' \
    --output text
# Should show: running

# 3. Check security group allows SSH from your IP
# Go to EC2 Console → Security Groups → Edit inbound rules
# Ensure port 22 allows your current IP

# 4. Verify correct IP
aws cloudformation describe-stacks \
    --stack-name CareFlowAI-Backend \
    --query 'Stacks[0].Outputs[?OutputKey==`ElasticIP`].OutputValue' \
    --output text
```

### Frontend Issues

**Frontend not loading:**
```bash
# 1. Check S3 bucket exists
aws s3 ls | grep careflowai

# 2. Check files uploaded
aws s3 ls s3://careflowai-frontend-123456789012/

# 3. Check bucket policy
aws s3api get-bucket-policy --bucket careflowai-frontend-123456789012

# 4. Try direct S3 URL (not CloudFront)
# http://careflowai-frontend-123456789012.s3-website-us-east-1.amazonaws.com
```

**CloudFront not working:**
```bash
# 1. Check distribution status
aws cloudfront get-distribution \
    --id E1234567890ABC \
    --query 'Distribution.Status' \
    --output text
# Should show: Deployed

# 2. Invalidate cache
aws cloudfront create-invalidation \
    --distribution-id E1234567890ABC \
    --paths "/*"

# 3. Wait 5-10 minutes for propagation
```

**API calls failing (CORS errors):**
```bash
# 1. Check frontend .env.production
cat frontend/.env.production
# Should have: VITE_API_URL=http://your-ec2-ip

# 2. Check CORS in backend
ssh -i ~/.ssh/careflowai-key.pem ubuntu@54.123.45.67
cat /opt/careflowai/backend/app/main.py
# Verify allow_origins includes your CloudFront domain

# 3. Rebuild and redeploy frontend
bash aws/scripts/deploy-frontend.sh
```

### Database Issues

**MongoDB connection failed:**
```bash
# 1. Test connection from EC2
ssh -i ~/.ssh/careflowai-key.pem ubuntu@54.123.45.67
cd /opt/careflowai/backend
source venv/bin/activate

# Test MongoDB connection
python3 -c "from pymongo import MongoClient; client = MongoClient('your-connection-string'); print(client.server_info())"

# If fails:
# - Check connection string in .env
# - Verify EC2 IP whitelisted in MongoDB Atlas
# - Check MongoDB Atlas cluster is running
```

### AWS CLI Issues

**AWS CLI not configured:**
```bash
# Check configuration
aws configure list

# Reconfigure
aws configure

# Test
aws sts get-caller-identity
```

**Permission denied:**
```bash
# Check IAM user permissions
# Go to IAM Console → Users → careflowai-admin
# Verify policies attached

# Or create new access key
aws iam create-access-key --user-name careflowai-admin
```

### CloudFormation Stack Failures

**Stack creation failed:**
```bash
# Check stack events
aws cloudformation describe-stack-events \
    --stack-name CareFlowAI-VPC \
    --max-items 20

# Delete failed stack
aws cloudformation delete-stack --stack-name CareFlowAI-VPC

# Wait for deletion
aws cloudformation wait stack-delete-complete --stack-name CareFlowAI-VPC

# Try again
bash aws/scripts/deploy-infrastructure.sh
```

---

## Post-Deployment Checklist

- [YES/NO] EC2 instance running
- [YES/NO] Backend service active
- [YES/NO] Backend health check passes
- [YES/NO] Frontend deployed to S3
- [YES/NO] CloudFront distribution active
- [YES/NO] Can access frontend via CloudFront
- [YES/NO] Can login to application
- [YES/NO] MongoDB connection working
- [YES/NO] All API endpoints responding
- [YES/NO] No console errors in browser

---

## Cost Monitoring

### Check Current Costs

```bash
# Get current month costs
aws ce get-cost-and-usage \
    --time-period Start=$(date -u +%Y-%m-01),End=$(date -u +%Y-%m-%d) \
    --granularity MONTHLY \
    --metrics BlendedCost \
    --group-by Type=SERVICE
```

### Set Billing Alert

1. **Go to Billing Console:**
   - https://console.aws.amazon.com/billing

2. **Create Budget:**
   - Left sidebar → Budgets
   - Click "Create budget"
   - Template: Zero spend budget
   - Or set custom amount: $10/month
   - Enter email for alerts
   - Click "Create"

---

## Updating the Application

### Update Backend

```bash
# SSH into EC2
ssh -i ~/.ssh/careflowai-key.pem ubuntu@54.123.45.67

# Pull latest code
cd /opt/careflowai
git pull origin main

# Update dependencies
cd backend
source venv/bin/activate
pip install -r requirements.txt

# Restart service
sudo systemctl restart careflowai-backend

# Check status
sudo systemctl status careflowai-backend

exit
```

### Update Frontend

```bash
# On local machine
cd CareFlowAI

# Pull latest code
git pull origin main

# Redeploy
bash aws/scripts/deploy-frontend.sh
```

---

## Summary

You've successfully deployed CareFlowAI to AWS! Here's what you have:

**Infrastructure:**
- VPC with public subnets
- EC2 instance with Elastic IP
- S3 bucket for frontend
- CloudFront distribution with HTTPS

**Applications:**
- FastAPI backend running as systemd service
- React frontend served via CloudFront
- MongoDB Atlas database (free tier)

**Access URLs:**
- Frontend: `https://d1234567890abc.cloudfront.net`
- Backend: `http://54.123.45.67`
- API Docs: `http://54.123.45.67/docs`

**Next Steps:**
1. Setup custom domain (optional)
2. Configure SSL on backend (optional)
3. Setup monitoring and alerts
4. Implement CI/CD pipeline
5. Add AI features with Gemini API

**Support:**
- AWS Console: https://console.aws.amazon.com
- MongoDB Atlas: https://cloud.mongodb.com
- Documentation: See aws/README.md

---

**Congratulations! Your application is live!** 🎉
