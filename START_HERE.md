# 🚀 START HERE - CareFlowAI Deployment Guide

**New to AWS? Confused about where to start? You're in the right place!**

---

## 📚 Which Document Should I Read?

We have several guides. Here's which one to use:

### **For Complete Beginners** ⭐ START HERE
👉 **[SIMPLE_AWS_DEPLOYMENT.md](SIMPLE_AWS_DEPLOYMENT.md)**

**Use this if:**
- ✅ You've never used AWS before
- ✅ You want step-by-step instructions with screenshots concepts
- ✅ You want everything explained in simple terms
- ✅ You need to know exactly what to click and type

**This guide has:**
- Simple language (no jargon)
- Exact commands to copy-paste
- Explanations of what everything does
- Troubleshooting for common issues

---

### **For Tracking Progress** 📋
👉 **[DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)**

**Use this if:**
- ✅ You want to track what you've completed
- ✅ You're following SIMPLE_AWS_DEPLOYMENT.md
- ✅ You want to make sure you don't miss any steps

**This guide has:**
- Checkbox lists for each step
- Space to write down important info
- Quick troubleshooting tips
- Status tracking

---

### **For Quick Commands** ⚡
👉 **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)**

**Use this if:**
- ✅ You already deployed and need quick commands
- ✅ You want to check if instances are running
- ✅ You need to start/stop resources
- ✅ You're looking for a specific AWS command

**This guide has:**
- All useful AWS CLI commands
- Quick status checks
- Common operations
- No explanations, just commands

---

### **For Detailed AWS Commands** 🛠️
👉 **[aws/AWS_CLI_COMMANDS.md](aws/AWS_CLI_COMMANDS.md)**

**Use this if:**
- ✅ You're comfortable with AWS CLI
- ✅ You need specific AWS service commands
- ✅ You want advanced CloudFormation operations
- ✅ You're debugging specific AWS resources

**This guide has:**
- Comprehensive AWS CLI reference
- EC2, S3, CloudFormation, VPC commands
- Monitoring and troubleshooting commands
- Cost management commands

---

### **For Architecture Understanding** 🏗️
👉 **[AWS_ARCHITECTURE_GUIDE.md](AWS_ARCHITECTURE_GUIDE.md)**

**Use this if:**
- ✅ You want to understand how everything connects
- ✅ You're interested in the system design
- ✅ You need to explain the architecture to someone
- ✅ You want to modify or scale the infrastructure

**This guide has:**
- System architecture diagrams
- Component explanations
- Infrastructure design decisions
- Scaling considerations

---

### **For Technical Details** 📖
👉 **[AWS_DEPLOYMENT_GUIDE.md](AWS_DEPLOYMENT_GUIDE.md)**

**Use this if:**
- ✅ You're an experienced AWS user
- ✅ You want detailed technical information
- ✅ You need to customize the deployment
- ✅ You prefer comprehensive documentation

**This guide has:**
- Full technical specifications
- CloudFormation template details
- Advanced configuration options
- Production deployment best practices

---

## 🎯 Recommended Path for Beginners

Follow this order:

```
1. SIMPLE_AWS_DEPLOYMENT.md
   ↓ (Read this first - follow all steps)

2. DEPLOYMENT_CHECKLIST.md
   ↓ (Check off items as you complete them)

3. QUICK_REFERENCE.md
   ↓ (Bookmark this for daily use)

4. AWS_ARCHITECTURE_GUIDE.md
   (Read when you want to understand how it all works)
```

---

## ⚡ Super Quick Start (5 minutes)

**Just want to see if your AWS is ready?**

### Step 1: Check AWS CLI
```bash
aws --version
# Should show: aws-cli/2.x.x

aws sts get-caller-identity
# Should show your AWS account info
```

✅ **Working?** Continue to Step 2
❌ **Not working?** Go to SIMPLE_AWS_DEPLOYMENT.md → Part 1

### Step 2: Check EC2 Key Pair
```bash
aws ec2 describe-key-pairs --query 'KeyPairs[*].KeyName' --output table
# Should show your key pair name
```

✅ **Have a key pair?** Continue to Step 3
❌ **No key pair?** Go to SIMPLE_AWS_DEPLOYMENT.md → Part 1, Step 5

### Step 3: Check if Already Deployed
```bash
bash aws/check-resources.sh
```

✅ **Resources found?** Your app is already deployed! Use QUICK_REFERENCE.md
❌ **No resources?** Time to deploy! Go to SIMPLE_AWS_DEPLOYMENT.md → Part 2

---

## 🆘 I'm Stuck! Quick Help

### Problem: "AWS CLI not found"
**Solution:** Install AWS CLI first
- Go to: SIMPLE_AWS_DEPLOYMENT.md → Part 1, Step 2

### Problem: "Could not connect to the endpoint URL"
**Solution:** Configure AWS CLI
```bash
aws configure
```
- Go to: SIMPLE_AWS_DEPLOYMENT.md → Part 1, Step 4

### Problem: "No resources found"
**Solution:** You need to deploy infrastructure
- Go to: SIMPLE_AWS_DEPLOYMENT.md → Part 2

### Problem: "Permission denied for .pem file"
**Solution:** Fix file permissions
```bash
# On Mac/Linux:
chmod 400 your-key.pem

# On Windows:
# Right-click .pem file → Properties → Security → Advanced
# Remove all users except yourself
```

### Problem: "I deployed but nothing works"
**Solution:** Check each component
```bash
# Check resources
bash aws/check-resources.sh

# Check backend logs (SSH into EC2 first)
sudo journalctl -u careflowai-backend -f
```
- Go to: DEPLOYMENT_CHECKLIST.md → Post-Deployment Verification

---

## 📁 Project Structure Quick Reference

```
CareFlowAI/
│
├── START_HERE.md                    ← You are here!
├── SIMPLE_AWS_DEPLOYMENT.md         ← Main deployment guide
├── DEPLOYMENT_CHECKLIST.md          ← Track your progress
├── QUICK_REFERENCE.md               ← Daily use commands
│
├── aws/
│   ├── scripts/
│   │   ├── deploy-infrastructure.sh ← Step 1: Run this first
│   │   ├── deploy-backend.sh        ← Step 2: Run this second
│   │   ├── deploy-frontend.sh       ← Step 3: Run this third
│   │   └── setup-nginx.sh           ← (Auto-run by deploy-backend)
│   │
│   ├── check-resources.sh           ← Check what's deployed
│   ├── startup-aws-resources.sh     ← Start stopped resources
│   ├── cleanup-aws-resources.sh     ← Delete everything
│   │
│   ├── cloudformation/              ← AWS infrastructure templates
│   ├── AWS_CLI_COMMANDS.md          ← All AWS commands
│   └── README.md                    ← AWS folder documentation
│
├── backend/                         ← FastAPI application
│   ├── .env.example                 ← Copy this to .env (on EC2)
│   └── requirements.txt
│
└── frontend/                        ← React application
    └── src/
```

---

## 🎯 What Do I Do Right Now?

### If you haven't deployed anything yet:

1. **Open:** [SIMPLE_AWS_DEPLOYMENT.md](SIMPLE_AWS_DEPLOYMENT.md)
2. **Start with:** Part 1 - Before You Start
3. **Follow:** Each step in order
4. **Track:** Check items off in [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)

### If you already deployed:

1. **Check status:** `bash aws/check-resources.sh`
2. **Use daily:** [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
3. **If issues:** See troubleshooting sections in each guide

### If you just want to understand:

1. **Read:** [AWS_ARCHITECTURE_GUIDE.md](AWS_ARCHITECTURE_GUIDE.md)
2. **Explore:** CloudFormation templates in `aws/cloudformation/`

---

## 💰 Cost Reminder

- **First 12 months:** FREE (AWS Free Tier)
- **After 12 months:** ~$10-15/month
- **MongoDB:** FREE forever (M0 cluster)

**To save money when not using:**
```bash
# Stop EC2 instance
aws ec2 stop-instances --instance-ids YOUR-INSTANCE-ID

# Start it again when needed
bash aws/startup-aws-resources.sh
```

---

## ✅ Success Checklist

You'll know everything is working when:

- [ ] ✅ `bash aws/check-resources.sh` shows running EC2 instance
- [ ] ✅ Can access `http://YOUR-IP/docs` in browser
- [ ] ✅ Can access `https://YOUR-CLOUDFRONT-DOMAIN` in browser
- [ ] ✅ Can login to the application
- [ ] ✅ Can create and view appointments

---

## 📞 Still Need Help?

1. **Check troubleshooting** in SIMPLE_AWS_DEPLOYMENT.md
2. **Review** DEPLOYMENT_CHECKLIST.md for missed steps
3. **Search** AWS_CLI_COMMANDS.md for specific commands
4. **Read** aws/STARTUP_TROUBLESHOOTING.md for common issues

---

## 🎓 Learning Path

**Day 1:** Setup AWS account and tools (Part 1)
**Day 2:** Deploy infrastructure (Part 2)
**Day 3:** Deploy backend (Part 3)
**Day 4:** Deploy frontend (Part 4)
**Day 5:** Test and customize

**Total time:** ~2-3 hours of actual work spread over a week

---

## 🚀 Ready to Begin?

👉 **[Click here to start: SIMPLE_AWS_DEPLOYMENT.md](SIMPLE_AWS_DEPLOYMENT.md)**

Good luck! You've got this! 💪

---

*Last updated: 2025*
*For issues or questions, check the troubleshooting sections in each guide.*
