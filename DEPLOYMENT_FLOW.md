# CareFlowAI Deployment Flow

## 📊 Visual Deployment Process

### The Big Picture

```
┌─────────────────────────────────────────────────────────────────┐
│                     What You're Building                        │
└─────────────────────────────────────────────────────────────────┘

    👤 User's Browser
         │
         │ (1) Visits website
         ▼
    ☁️ CloudFront (CDN)
         │
         │ (2) Serves React frontend
         ▼
    📦 S3 Bucket (Static Files)
         │
         │ (3) Makes API calls
         ▼
    🖥️ EC2 Instance (Virtual Computer)
         │
         ├─ Nginx (Web Server)
         ├─ FastAPI (Backend)
         │
         │ (4) Queries database
         ▼
    🗄️ MongoDB Atlas (Database)
```

---

## 🔄 Step-by-Step Deployment Flow

### Phase 1: Setup (Before Deployment)

```
┌─────────────┐
│  Your       │
│  Computer   │
└──────┬──────┘
       │
       │ 1. Install AWS CLI
       │ 2. Configure credentials
       │ 3. Create EC2 key pair
       │ 4. Setup MongoDB Atlas
       │
       ▼
┌─────────────┐
│   Ready     │
│   to Deploy │
└─────────────┘
```

**Time:** 15 minutes
**File:** SIMPLE_AWS_DEPLOYMENT.md (Part 1)

---

### Phase 2: Infrastructure Deployment

```
┌────────────────────────────────────────────────────────┐
│  Run: bash aws/scripts/deploy-infrastructure.sh       │
└────────────────┬───────────────────────────────────────┘
                 │
    ┌────────────┴────────────┐
    │                         │
    ▼                         ▼
Creates VPC              Creates EC2
(Network)                (Server)
    │                         │
    │                         ├─ Elastic IP
    │                         ├─ Security Groups
    │                         └─ IAM Roles
    │
    ▼                         ▼
Creates S3              Creates CloudFront
(Storage)               (CDN)
    │
    ▼
┌─────────────────────────────┐
│  Infrastructure Ready ✅    │
│  Save: Elastic IP           │
│  Save: S3 Bucket Name       │
│  Save: CloudFront Domain    │
└─────────────────────────────┘
```

**Time:** 25-30 minutes
**File:** SIMPLE_AWS_DEPLOYMENT.md (Part 2)
**What it creates:**
- VPC (your private network in AWS)
- EC2 instance (a virtual computer)
- S3 bucket (storage for frontend files)
- CloudFront (CDN to serve frontend fast globally)

---

### Phase 3: Backend Deployment

```
┌────────────────────────────────────────────┐
│  SSH into EC2                              │
│  ssh -i key.pem ubuntu@YOUR-ELASTIC-IP     │
└────────────────┬───────────────────────────┘
                 │
                 ▼
        ┌────────────────┐
        │ Install System │
        │ Dependencies   │
        └────────┬───────┘
                 │
                 ├─ Python 3
                 ├─ Nginx
                 └─ Git
                 │
                 ▼
        ┌────────────────┐
        │ Setup Backend  │
        └────────┬───────┘
                 │
                 ├─ Clone/Copy code
                 ├─ Create .env file
                 ├─ Install Python packages
                 ├─ Initialize database
                 └─ Create admin user
                 │
                 ▼
        ┌────────────────┐
        │ Configure      │
        │ Services       │
        └────────┬───────┘
                 │
                 ├─ Systemd (auto-start backend)
                 └─ Nginx (web server/proxy)
                 │
                 ▼
        ┌────────────────┐
        │ Backend        │
        │ Running ✅     │
        │ Test: http://  │
        │ IP/docs        │
        └────────────────┘
```

**Time:** 15 minutes
**File:** SIMPLE_AWS_DEPLOYMENT.md (Part 3)
**Result:** Backend API running at http://YOUR-IP/docs

---

### Phase 4: Frontend Deployment

```
┌────────────────────────────────────────────────┐
│  Run: bash aws/scripts/deploy-frontend.sh     │
└────────────────┬───────────────────────────────┘
                 │
                 ▼
        ┌────────────────┐
        │ Build Frontend │
        └────────┬───────┘
                 │
                 ├─ Install npm packages
                 ├─ Create .env.production
                 ├─ Run: npm run build
                 └─ Create optimized bundle
                 │
                 ▼
        ┌────────────────┐
        │ Upload to S3   │
        └────────┬───────┘
                 │
                 ├─ Sync dist/ folder
                 └─ Set permissions
                 │
                 ▼
        ┌────────────────┐
        │ Clear CloudFront│
        │ Cache          │
        └────────┬───────┘
                 │
                 ▼
        ┌────────────────┐
        │ Frontend       │
        │ Live ✅        │
        │ https://       │
        │ cloudfront.net │
        └────────────────┘
```

**Time:** 10 minutes
**File:** SIMPLE_AWS_DEPLOYMENT.md (Part 4)
**Result:** Frontend live at https://YOUR-CLOUDFRONT-DOMAIN

---

## 🎯 The Complete Data Flow (After Deployment)

```
1. User Types URL
   │
   ├─ https://d123456.cloudfront.net
   │
   ▼
2. CloudFront (CDN)
   │
   ├─ Checks cache
   ├─ If not cached, gets from S3
   │
   ▼
3. Returns React App (HTML/JS/CSS)
   │
   ▼
4. Browser Loads React
   │
   ├─ User sees login page
   ├─ User clicks "Login"
   │
   ▼
5. React Makes API Call
   │
   ├─ POST http://54.123.45.67/api/auth/login
   │
   ▼
6. Nginx Receives Request
   │
   ├─ Listens on port 80
   ├─ Forwards to localhost:8000
   │
   ▼
7. FastAPI Processes Request
   │
   ├─ Validates credentials
   ├─ Queries MongoDB
   │
   ▼
8. MongoDB Atlas Returns Data
   │
   ├─ User found ✅
   ├─ Password matches ✅
   │
   ▼
9. FastAPI Returns JWT Token
   │
   ▼
10. React Stores Token
   │
   ├─ Redirects to dashboard
   ├─ Makes authenticated requests
   │
   ▼
11. User Uses Application! 🎉
```

---

## 🔧 Daily Operations Flow

### Starting Your Day

```
1. Check if resources are running
   bash aws/check-resources.sh
   │
   ├─ Running? ✅
   │  └─ Go to your app
   │
   └─ Stopped? ❌
      └─ bash aws/startup-aws-resources.sh
```

### Updating Backend Code

```
1. Make changes locally
   │
   ▼
2. Push to GitHub
   git push origin main
   │
   ▼
3. SSH into EC2
   ssh -i key.pem ubuntu@YOUR-IP
   │
   ▼
4. Pull changes
   cd /opt/careflowai
   git pull origin main
   │
   ▼
5. Restart service
   sudo systemctl restart careflowai-backend
   │
   ▼
6. Test
   curl http://localhost:8000/health
```

### Updating Frontend Code

```
1. Make changes locally
   │
   ▼
2. Run deploy script
   bash aws/scripts/deploy-frontend.sh
   │
   ├─ Builds new version
   ├─ Uploads to S3
   └─ Clears CloudFront cache
   │
   ▼
3. Wait 2-3 minutes
   │
   ▼
4. Refresh browser
   See new version! ✅
```

---

## 🆘 Troubleshooting Flow

### Problem: Frontend Not Loading

```
1. Check CloudFront status
   aws cloudfront get-distribution --id YOUR-ID
   │
   ├─ Status: Deployed ✅
   │  └─ Check S3 bucket has files
   │
   └─ Status: InProgress ⏳
      └─ Wait 15-20 minutes
```

### Problem: Backend Not Responding

```
1. Check EC2 instance
   bash aws/check-resources.sh
   │
   ├─ Running ✅
   │  └─ Check backend service
   │     ssh into EC2
   │     sudo systemctl status careflowai-backend
   │
   └─ Stopped ❌
      └─ Start instance
         aws ec2 start-instances --instance-ids i-xxxxx
```

### Problem: Database Connection Failed

```
1. Check MongoDB Atlas
   │
   ├─ Cluster running? ✅
   │  └─ Check network access
   │     Is EC2 IP whitelisted?
   │
   └─ Cluster stopped? ❌
      └─ Clusters don't stop (M0 always on)
          Check connection string in .env
```

---

## 📈 Scaling Flow (Future)

```
Current Setup (Free Tier)
┌──────────────────┐
│  1 EC2 Instance  │
│  (t2.micro)      │
└──────────────────┘

When you need more:

Small Growth (100 users)
┌──────────────────┐
│  1 EC2 Instance  │
│  (t3.small)      │ ← Upgrade instance type
└──────────────────┘

Medium Growth (1000 users)
┌──────────────────┐
│  Load Balancer   │
└────────┬─────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌────────┐ ┌────────┐
│EC2 #1  │ │EC2 #2  │ ← Multiple instances
└────────┘ └────────┘

Large Growth (10,000+ users)
┌──────────────────┐
│   EKS Cluster    │
│   (Kubernetes)   │ ← Container orchestration
└──────────────────┘
```

---

## 💡 Quick Reference

### Files You Need to Edit

```
Before deployment:
✏️ aws/scripts/deploy-infrastructure.sh (line 13: KEY_NAME)

After infrastructure:
✏️ aws/scripts/deploy-backend.sh (lines 11-15: all config)
✏️ aws/scripts/deploy-frontend.sh (lines 11-13: all config)

On EC2 server:
✏️ backend/.env (create this file with all your secrets)
```

### Commands You'll Use Daily

```bash
# Check everything
bash aws/check-resources.sh

# Start stopped resources
bash aws/startup-aws-resources.sh

# SSH into server
ssh -i your-key.pem ubuntu@YOUR-IP

# View logs
sudo journalctl -u careflowai-backend -f

# Restart backend
sudo systemctl restart careflowai-backend
```

---

## ✅ Deployment Complete Indicator

You'll know you're done when:

```
✅ Infrastructure deployed (VPC, EC2, S3, CloudFront)
   └─ Can see resources in AWS Console

✅ Backend deployed (FastAPI running)
   └─ http://YOUR-IP/docs shows API documentation

✅ Frontend deployed (React app live)
   └─ https://YOUR-CLOUDFRONT/login shows login page

✅ Database connected (MongoDB Atlas)
   └─ Can login with admin credentials

✅ Everything works together
   └─ Can create/view appointments through the UI
```

---

**Need more details? → [SIMPLE_AWS_DEPLOYMENT.md](SIMPLE_AWS_DEPLOYMENT.md)**

**Ready to start? → [START_HERE.md](START_HERE.md)**
