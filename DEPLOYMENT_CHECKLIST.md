# CareFlowAI Deployment Checklist

Use this checklist to track your deployment progress!

## ☑️ Pre-Deployment (Setup)

### AWS Account Setup
- [ ] Created AWS account
- [ ] Verified email and phone
- [ ] Added payment method (for verification)

### AWS CLI Setup
- [ ] Installed AWS CLI (`aws --version` works)
- [ ] Created AWS access keys (Access Key ID + Secret Key)
- [ ] Ran `aws configure` and entered credentials
- [ ] Tested with `aws sts get-caller-identity`

### EC2 Key Pair
- [ ] Created key pair named `CareFlowAI-Key` (or your choice)
- [ ] Downloaded .pem file
- [ ] Saved .pem file to safe location
- [ ] Know the path to your .pem file

### MongoDB Atlas
- [ ] Created MongoDB Atlas account
- [ ] Created FREE M0 cluster
- [ ] Created database user (username + password saved)
- [ ] Got connection string
- [ ] Replaced `<password>` in connection string with actual password

---

## ☑️ Infrastructure Deployment

### Edit Configuration
- [ ] Opened `aws/scripts/deploy-infrastructure.sh`
- [ ] Set `KEY_NAME` to your key pair name (line 13)
- [ ] Saved the file

### Run Deployment
- [ ] Opened terminal in project folder
- [ ] Ran: `bash aws/scripts/deploy-infrastructure.sh`
- [ ] Waited ~25-30 minutes for completion
- [ ] Deployment completed successfully ✅

### Save Important Info
- [ ] Saved VPC ID
- [ ] Saved Security Group ID
- [ ] **Saved EC2 Elastic IP** (IMPORTANT!)
- [ ] Saved S3 Bucket name
- [ ] Saved CloudFront Domain

### Update MongoDB Access
- [ ] Went to MongoDB Atlas → Network Access
- [ ] Added EC2 Elastic IP to whitelist
- [ ] Confirmed access granted

---

## ☑️ Backend Deployment

### Prepare Deployment Script
- [ ] Opened `aws/scripts/deploy-backend.sh`
- [ ] Set `EC2_IP` to your Elastic IP
- [ ] Set `KEY_FILE` to path of your .pem file
- [ ] Set `REPO_URL` to your GitHub repo (or leave empty if uploading files)
- [ ] Set `MONGODB_URL` to your MongoDB connection string
- [ ] Generated SECRET_KEY with `openssl rand -hex 32`
- [ ] Set `SECRET_KEY` in the script
- [ ] Saved the file

### Upload Backend Files
Choose ONE method:

**Method A: Using SCP (if not using GitHub)**
- [ ] Ran: `scp -i "your-key.pem" -r backend ubuntu@YOUR-ELASTIC-IP:/tmp/`

**Method B: Using GitHub**
- [ ] Pushed code to GitHub
- [ ] Updated `REPO_URL` in deploy script

### SSH and Setup
- [ ] Connected via SSH: `ssh -i "your-key.pem" ubuntu@YOUR-ELASTIC-IP`
- [ ] Ran system update: `sudo apt-get update && sudo apt-get upgrade -y`
- [ ] Installed dependencies: `sudo apt-get install -y python3-pip python3-venv nginx`
- [ ] Created project directory: `sudo mkdir -p /opt/careflowai`
- [ ] Set ownership: `sudo chown ubuntu:ubuntu /opt/careflowai`
- [ ] Copied/cloned backend code to `/opt/careflowai/backend`

### Setup Python Environment
- [ ] Went to backend directory: `cd /opt/careflowai/backend`
- [ ] Created venv: `python3 -m venv venv`
- [ ] Activated venv: `source venv/bin/activate`
- [ ] Installed requirements: `pip install -r requirements.txt`

### Configure Environment
- [ ] Created `.env` file with all required variables
- [ ] Created uploads directory: `mkdir -p /opt/careflowai/backend/uploads`
- [ ] Ran database init: `python scripts/init_db.py`
- [ ] Added admin user: `python scripts/add_admin.py`
- [ ] Tested backend: `python run.py` (then Ctrl+C)

### Setup Systemd Service
- [ ] Created service file: `/etc/systemd/system/careflowai-backend.service`
- [ ] Reloaded systemd: `sudo systemctl daemon-reload`
- [ ] Enabled service: `sudo systemctl enable careflowai-backend`
- [ ] Started service: `sudo systemctl start careflowai-backend`
- [ ] Verified status shows "active (running)"

### Setup Nginx
- [ ] Created nginx config: `/etc/nginx/sites-available/careflowai`
- [ ] Enabled site: `sudo ln -s /etc/nginx/sites-available/careflowai /etc/nginx/sites-enabled/`
- [ ] Removed default: `sudo rm /etc/nginx/sites-enabled/default`
- [ ] Tested config: `sudo nginx -t`
- [ ] Restarted nginx: `sudo systemctl restart nginx`
- [ ] Exited SSH

### Test Backend
- [ ] Opened browser to `http://YOUR-ELASTIC-IP/docs`
- [ ] API documentation loaded successfully ✅
- [ ] Tried the `/health` endpoint
- [ ] Health check returned OK ✅

---

## ☑️ Frontend Deployment

### Get CloudFront Info
- [ ] Went to [CloudFront Console](https://console.aws.amazon.com/cloudfront)
- [ ] Found the distribution
- [ ] Copied Distribution ID (starts with E)
- [ ] Saved Distribution ID

### Edit Deployment Script
- [ ] Opened `aws/scripts/deploy-frontend.sh`
- [ ] Set `S3_BUCKET` to your bucket name
- [ ] Set `CLOUDFRONT_DISTRIBUTION_ID` to distribution ID
- [ ] Set `API_URL` to `http://YOUR-ELASTIC-IP`
- [ ] Saved the file

### Run Deployment
- [ ] Ran: `bash aws/scripts/deploy-frontend.sh`
- [ ] Build completed successfully
- [ ] Files uploaded to S3
- [ ] CloudFront cache invalidated

### Test Frontend
- [ ] Opened browser to CloudFront domain
- [ ] Frontend loaded successfully ✅
- [ ] Tried logging in (if you have test user)
- [ ] Frontend connects to backend ✅

---

## ☑️ Post-Deployment Verification

### Check All Resources
- [ ] Ran: `bash aws/check-resources.sh`
- [ ] Verified EC2 instance is running
- [ ] Verified S3 bucket exists
- [ ] Verified CloudFront distribution is active

### Test Application Features
- [ ] Login works
- [ ] Can create/view appointments
- [ ] AI features work (if configured)
- [ ] All pages load correctly

### Save Important URLs
- [ ] Frontend URL: `https://_____.cloudfront.net`
- [ ] Backend API: `http://_____/docs`
- [ ] SSH Command: `ssh -i "_____.pem" ubuntu@_____`

---

## ☑️ Security Review

- [ ] Changed default admin password
- [ ] EC2 security group allows only necessary ports (22, 80, 443)
- [ ] MongoDB has strong password
- [ ] SECRET_KEY is strong (32+ characters)
- [ ] .pem file has restricted permissions (chmod 400 on Linux/Mac)
- [ ] Environment variables are not in git
- [ ] Access keys are not in git

---

## ☑️ Optional Enhancements

- [ ] Added custom domain name
- [ ] Enabled HTTPS with SSL certificate
- [ ] Setup CloudWatch monitoring
- [ ] Setup automated backups
- [ ] Setup CI/CD pipeline
- [ ] Created staging environment

---

## 🆘 If Something Fails

### Infrastructure Deployment Failed
```bash
# Check CloudFormation console for error
# Go to: https://console.aws.amazon.com/cloudformation
# Click on stack → Events tab → Look for errors
```

### Backend Not Starting
```bash
ssh -i your-key.pem ubuntu@YOUR-ELASTIC-IP
sudo journalctl -u careflowai-backend -n 100
# Look for error messages
```

### Frontend Not Loading
```bash
# Check S3 bucket has files
aws s3 ls s3://YOUR-BUCKET-NAME/

# Check CloudFront distribution status
aws cloudfront get-distribution --id YOUR-DISTRIBUTION-ID
```

### Can't Connect to MongoDB
```bash
# Test connection from EC2
ssh -i your-key.pem ubuntu@YOUR-ELASTIC-IP
cd /opt/careflowai/backend
source venv/bin/activate
python3 -c "from pymongo import MongoClient; client = MongoClient('YOUR-CONNECTION-STRING'); print(client.server_info())"
```

---

## 📊 Deployment Status

**Started:** _______________
**Completed:** _______________
**Total Time:** _______________

**Issues Encountered:**
1. _______________________________
2. _______________________________
3. _______________________________

**Solutions Applied:**
1. _______________________________
2. _______________________________
3. _______________________________

---

## 📝 Notes & Reminders

- MongoDB Atlas connection string: `_________________________________`
- EC2 Elastic IP: `_________________________________`
- CloudFront URL: `_________________________________`
- Admin username: `_________________________________`
- Admin password: `_________________________________`

---

## ✅ Deployment Complete!

When all boxes are checked, your CareFlowAI application is fully deployed and running on AWS! 🎉

**Next Steps:**
1. Share the CloudFront URL with users
2. Monitor usage and costs
3. Setup regular backups
4. Plan for scaling if needed

---

**💡 Pro Tip:** Bookmark these pages:
- [AWS EC2 Console](https://console.aws.amazon.com/ec2)
- [MongoDB Atlas](https://cloud.mongodb.com)
- [CloudWatch Logs](https://console.aws.amazon.com/cloudwatch)
- Your Frontend: `https://YOUR-DOMAIN`
- Your API Docs: `http://YOUR-IP/docs`
