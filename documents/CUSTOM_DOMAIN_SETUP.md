# Custom Domain Setup Guide for CareFlowAI

This guide shows you how to use a custom domain like `careflowai.com` instead of the CloudFront URL.

---

## Overview

**What you'll set up:**
- `careflowai.com` → Frontend (CloudFront/S3)
- `api.careflowai.com` → Backend (EC2)

**Time Required:** 1-2 hours
**Cost:** $12-15/year for domain + $0.50/month for Route 53

---

## Step 1: Purchase a Domain Name

### Option A: AWS Route 53 (Recommended - Easier Setup)

1. Go to [Route 53 Console](https://console.aws.amazon.com/route53)
2. Click **"Register Domain"**
3. Search for your domain (e.g., `careflowai.com`)
4. Check availability and pricing:
   - `.com` domains: ~$13/year
   - `.io` domains: ~$39/year
   - `.net` domains: ~$12/year
5. Click **"Add to cart"** → **"Continue"**
6. Fill in contact information
7. Complete purchase

**Processing Time:** 10 minutes - 24 hours

### Option B: Other Registrars (GoDaddy, Namecheap, etc.)

1. Purchase domain from your preferred registrar
2. Note: You'll need to configure nameservers later (extra step)

**For this guide, we'll use Route 53 as it's simpler.**

---

## Step 2: Create SSL Certificate (for HTTPS)

**Why?** To enable HTTPS on `careflowai.com`

1. Go to [AWS Certificate Manager (ACM)](https://console.aws.amazon.com/acm/home?region=us-east-1)
   - **IMPORTANT:** Select **us-east-1** region (required for CloudFront)

2. Click **"Request a certificate"**

3. Select **"Request a public certificate"** → **"Next"**

4. Add domain names:
   ```
   careflowai.com
   *.careflowai.com
   ```
   The `*` (wildcard) covers all subdomains like `api.careflowai.com`

5. **Validation method:** Select **"DNS validation"**

6. Click **"Request"**

7. **Validate the certificate:**
   - Click on the certificate you just created
   - You'll see validation records for each domain
   - Click **"Create records in Route 53"** (automatic if you used Route 53 for domain)
   - Click **"Create records"**

8. **Wait for validation:**
   - Status will change from "Pending validation" to "Issued"
   - Usually takes 5-30 minutes
   - You can refresh the page to check status

---

## Step 3: Configure CloudFront for Frontend

### 3.1 Add Custom Domain to CloudFront

1. Go to [CloudFront Console](https://console.aws.amazon.com/cloudfront)
2. Click on your distribution ID: `ELQ36TVX16I3O`
3. Click **"Edit"**
4. Find **"Alternate domain names (CNAMEs)"**
5. Click **"Add item"** and enter: `careflowai.com`
6. In **"Custom SSL certificate"** section:
   - Click the dropdown
   - Select the certificate you created in Step 2
   - It should show: `careflowai.com (and 1 more)`
7. Click **"Save changes"**
8. **Wait 5-10 minutes** for changes to deploy

### 3.2 Create Route 53 DNS Record for Frontend

1. Go to [Route 53 Console](https://console.aws.amazon.com/route53)
2. Click **"Hosted zones"**
3. Click on your domain: `careflowai.com`
4. Click **"Create record"**
5. Configure:
   - **Record name:** Leave empty (for root domain)
   - **Record type:** `A - Routes traffic to an IPv4 address`
   - **Alias:** Toggle ON (switch to Yes)
   - **Route traffic to:**
     - Select: "Alias to CloudFront distribution"
     - Select your distribution: `d1bf7p1xlxrfne.cloudfront.net`
   - **Routing policy:** Simple routing
6. Click **"Create records"**

**Wait 5-10 minutes for DNS propagation.**

**Test:** Open browser and go to `https://careflowai.com`

---

## Step 4: Setup Custom Domain for Backend API

You have two options for the backend:

### Option A: Use Subdomain with EC2 Elastic IP (Simple - No HTTPS)

**URL:** `http://api.careflowai.com`

1. Go to [Route 53 Console](https://console.aws.amazon.com/route53)
2. Click **"Hosted zones"** → Click `careflowai.com`
3. Click **"Create record"**
4. Configure:
   - **Record name:** `api`
   - **Record type:** `A - Routes traffic to an IPv4 address`
   - **Value:** `54.225.66.151` (your EC2 Elastic IP)
   - **TTL:** `300`
5. Click **"Create records"**

**Update Frontend:**
```bash
# Edit: frontend/.env.production
VITE_API_URL=http://api.careflowai.com

# Edit: aws/scripts/deploy-frontend.sh
API_URL="http://api.careflowai.com"

# Redeploy frontend
bash aws/scripts/deploy-frontend.sh
```

**Update Backend CORS:**
```bash
# Edit: backend/app/main.py
# Add to allow_origins list:
"https://careflowai.com",

# Deploy to EC2
bash aws/scripts/deploy-backend.sh

# Restart backend
ssh -i ~/.ssh/CareFlowAI-Key-New.pem ubuntu@54.225.66.151 "sudo systemctl restart careflowai"
```

**⚠️ Issue:** Frontend is HTTPS but backend is HTTP → Mixed Content blocking!

### Option B: Use Application Load Balancer with HTTPS (Recommended for Production)

**URL:** `https://api.careflowai.com`

This solves the Mixed Content issue by enabling HTTPS on backend.

#### 4.1 Create Application Load Balancer

1. Go to [EC2 Console](https://console.aws.amazon.com/ec2)
2. Left sidebar → **"Load Balancers"** → **"Create Load Balancer"**
3. Select **"Application Load Balancer"** → **"Create"**
4. Configure:
   - **Name:** `careflowai-alb`
   - **Scheme:** Internet-facing
   - **IP address type:** IPv4
   - **VPC:** Select your CareFlowAI VPC
   - **Subnets:** Select at least 2 availability zones
   - **Security groups:**
     - Create new or select existing
     - Allow inbound: HTTP (80) and HTTPS (443) from 0.0.0.0/0
5. **Listeners:**
   - Add listener: HTTPS:443
   - **Default SSL certificate:** Select the certificate from Step 2
6. Click **"Next: Configure Routing"**

#### 4.2 Create Target Group

1. **Target group name:** `careflowai-backend`
2. **Target type:** Instances
3. **Protocol:** HTTP
4. **Port:** 80 (nginx is listening on 80)
5. **VPC:** Same as ALB
6. **Health check:**
   - **Protocol:** HTTP
   - **Path:** `/health`
   - **Advanced settings:**
     - Healthy threshold: 2
     - Interval: 30 seconds
7. Click **"Next: Register Targets"**
8. Select your EC2 instance (CareFlowAI backend)
9. Click **"Include as pending below"**
10. Click **"Next: Review"** → **"Create"**

#### 4.3 Create Route 53 Record for ALB

1. Go to [Route 53 Console](https://console.aws.amazon.com/route53)
2. Click **"Hosted zones"** → Click `careflowai.com`
3. Click **"Create record"**
4. Configure:
   - **Record name:** `api`
   - **Record type:** `A`
   - **Alias:** ON (Yes)
   - **Route traffic to:**
     - Select: "Alias to Application and Classic Load Balancer"
     - Region: us-east-1
     - Select your ALB: `careflowai-alb`
5. Click **"Create records"**

**Wait 5-10 minutes for DNS and ALB setup to complete.**

#### 4.4 Update Application Configuration

**Update Frontend:**
```bash
# Edit: frontend/.env.production
VITE_API_URL=https://api.careflowai.com

# Edit: aws/scripts/deploy-frontend.sh
API_URL="https://api.careflowai.com"

# Redeploy
bash aws/scripts/deploy-frontend.sh
```

**Update Backend CORS:**
```bash
# Edit: backend/app/main.py
# Update allow_origins to:
allow_origins=[
    "http://localhost:5173",
    "http://localhost:3000",
    "http://127.0.0.1:5173",
    "http://127.0.0.1:3000",
    "https://careflowai.com",
    "https://www.careflowai.com",
],

# Deploy to EC2
bash aws/scripts/deploy-backend.sh

# Restart backend
ssh -i ~/.ssh/CareFlowAI-Key-New.pem ubuntu@54.225.66.151 "sudo systemctl restart careflowai"
```

---

## Step 5: Verify Everything Works

### Test DNS Resolution

```bash
# Test frontend domain
nslookup careflowai.com
# Should point to CloudFront

# Test backend domain
nslookup api.careflowai.com
# Should point to ALB or EC2 IP
```

### Test in Browser

1. **Frontend:** `https://careflowai.com`
   - Should load the login page
   - Check browser console for errors

2. **Backend:** `https://api.careflowai.com/docs` (if using ALB)
   - Should show API documentation

3. **Test Health Report Upload:**
   - Login to frontend
   - Try uploading a health report
   - Should work without Mixed Content errors

---

## Cost Breakdown

| Item | Cost |
|------|------|
| Domain (.com) | $13/year |
| Route 53 Hosted Zone | $0.50/month |
| SSL Certificate (ACM) | **FREE** |
| Application Load Balancer (optional) | $16/month |
| **Total (without ALB)** | **$19/year** |
| **Total (with ALB)** | **$211/year** |

---

## Troubleshooting

### Domain not resolving

**Wait time:** DNS changes can take 5-48 hours to propagate globally
**Quick check:** Use [DNS Checker](https://dnschecker.org)

### SSL Certificate stuck in "Pending validation"

- Make sure you created the CNAME records in Route 53
- Wait up to 30 minutes
- Check Route 53 has the validation records

### Mixed Content errors in browser

- **Solution 1:** Use HTTP for both frontend and backend (not secure)
- **Solution 2:** Use HTTPS for both (requires ALB or SSL on EC2)

### ALB health checks failing

```bash
# SSH to EC2 and check backend
ssh -i ~/.ssh/CareFlowAI-Key-New.pem ubuntu@54.225.66.151

# Test health endpoint
curl http://localhost/health

# Check nginx status
sudo systemctl status nginx

# Check backend status
sudo systemctl status careflowai
```

---

## Summary

**Quick Setup (HTTP Backend):**
1. ✅ Buy domain on Route 53
2. ✅ Request SSL certificate for `careflowai.com` and `*.careflowai.com`
3. ✅ Add domain to CloudFront with SSL
4. ✅ Create A record: `careflowai.com` → CloudFront
5. ✅ Create A record: `api.careflowai.com` → EC2 IP
6. ⚠️ Issue: Mixed Content (HTTPS → HTTP blocked)

**Production Setup (HTTPS Backend):**
1. ✅ Same steps 1-4 as above
2. ✅ Create Application Load Balancer with HTTPS
3. ✅ Create A record: `api.careflowai.com` → ALB
4. ✅ Update frontend and backend configs
5. ✅ Everything works with HTTPS

---

## Next Steps

After domain setup:
1. Update frontend environment variables
2. Update backend CORS settings
3. Redeploy both frontend and backend
4. Test thoroughly
5. Update documentation with new URLs

**Recommended:** Use Option B (ALB with HTTPS) for production to avoid Mixed Content issues.
