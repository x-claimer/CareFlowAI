# AWS Services Used and Cost Comparison

Complete breakdown of AWS services used in CareFlowAI and detailed cost analysis.

## Table of Contents

1. [Services Currently Used](#services-currently-used)
2. [Services NOT Used](#services-not-used)
3. [Cost Comparison](#cost-comparison)
4. [Architecture Decisions](#architecture-decisions)
5. [Free Tier Benefits](#free-tier-benefits)
6. [Cost Optimization Tips](#cost-optimization-tips)
7. [Scaling Cost Projections](#scaling-cost-projections)

---

## Services Currently Used

### Compute Services

#### **EC2 (Elastic Compute Cloud)** ✅
- **Instance Type**: t2.micro (1 vCPU, 1GB RAM)
- **Purpose**: Backend FastAPI application hosting
- **Configuration**:
  - OS: Ubuntu 22.04 LTS
  - Storage: 30GB gp3 EBS (encrypted)
  - Elastic IP: Static public address
- **Auto Scaling**: 1-3 instances based on CPU (70%) and requests (1000/target)
- **Cost**: $8.50/month per instance
- **Free Tier**: 750 hours/month for first 12 months

#### **Auto Scaling** ✅
- **Purpose**: Automatic instance scaling
- **Configuration**:
  - Min: 1, Max: 3, Desired: 1
  - Health check type: ELB
  - Scaling policies: CPU and request-based
- **Cost**: Free (pay only for EC2 instances)

### Networking & Content Delivery

#### **VPC (Virtual Private Cloud)** ✅
- **Configuration**:
  - CIDR: 10.0.0.0/16
  - 2 Public Subnets across 2 AZs
  - Internet Gateway
  - Route Tables
- **Purpose**: Network isolation and security
- **Cost**: Free

#### **Application Load Balancer (ALB)** ✅
- **Purpose**: Distribute traffic across EC2 instances
- **Configuration**:
  - Type: Application Load Balancer
  - Scheme: Internet-facing
  - Health checks on `/health`
  - Sticky sessions enabled (24 hours)
- **Cost**: ~$16.20/month + data processing fees
- **Breakdown**:
  - Fixed: $0.0225/hour × 730 hours = $16.43
  - LCU (Load Balancer Capacity Units): Variable

#### **API Gateway (HTTP API)** ✅
- **Purpose**: Public API endpoint management
- **Configuration**:
  - Type: HTTP API (not REST API)
  - VPC Link for private ALB connection
  - Rate limiting: 500 req/sec, burst 1000
  - CORS enabled
- **Cost**: $1.00/million requests (first 1M free)
- **Free Tier**: 1 million requests/month for 12 months

#### **CloudFront** ✅
- **Purpose**: CDN for React frontend
- **Configuration**:
  - Origin: S3 bucket
  - HTTPS redirect enabled
  - Compression enabled
  - Custom error pages for SPA routing
  - Price class: 100 (North America & Europe)
- **Cost**: $0.085/GB data transfer + $0.01/10,000 requests
- **Free Tier**: 1TB data transfer out, 10M requests/month

#### **Elastic IP** ✅
- **Purpose**: Static public IP for EC2
- **Cost**: Free while attached to running instance
- **Cost if unused**: $0.005/hour (~$3.65/month)

#### **Security Groups** ✅
- **Purpose**: Virtual firewalls
- **Configuration**:
  - Backend SG: Ports 22, 80, 8000
  - ALB SG: Ports 80, 443
  - VPC Link SG: ALB communication
- **Cost**: Free

### Storage Services

#### **S3 (Simple Storage Service)** ✅
- **Purpose**: Frontend hosting (React build)
- **Configuration**:
  - Website hosting enabled
  - Public read access
  - Versioning suspended
- **Typical Size**: 5-10 MB (React app)
- **Cost**: $0.023/GB storage + $0.0004/1000 GET requests
- **Estimate**: ~$0.50/month
- **Free Tier**: 5GB storage, 20,000 GET requests, 2,000 PUT requests

#### **EBS (Elastic Block Store)** ✅
- **Purpose**: EC2 instance storage
- **Configuration**:
  - Volume type: gp3
  - Size: 30GB per instance
  - Encryption: Enabled
- **Cost**: $0.08/GB-month = $2.40/month per instance
- **Free Tier**: 30GB included with EC2 free tier

### Database

#### **MongoDB Atlas** ✅ (Third-party, not AWS)
- **Tier**: M0 (Free forever)
- **Storage**: 512 MB
- **Configuration**:
  - Shared cluster
  - Hosted on AWS infrastructure
  - Connection via internet (not VPC peering)
- **Cost**: $0 (Free tier)
- **Upgrade Options**: M2 ($9/month), M5 ($25/month)

### Identity & Access Management

#### **IAM (Identity and Access Management)** ✅
- **Resources**:
  - Roles for EC2 instances
  - Instance profiles
  - Custom policies
- **Attached Policies**:
  - CloudWatchAgentServerPolicy (managed)
  - AmazonSSMManagedInstanceCore (managed)
  - Custom policies for CloudWatch Logs, SSM, Lambda
- **Cost**: Free

### Monitoring & Logging

#### **CloudWatch** ✅
- **Log Groups**:
  - `/careflowai/backend` (30-day retention)
  - `/aws/apigateway/CareFlowAI` (7-day retention)
- **Custom Metrics**:
  - CPU, Memory, Disk usage
  - TCP connections
- **Alarms**:
  - 8 alarms (latency, errors, CPU, memory, disk)
- **Dashboard**: 8 widgets with key metrics
- **Cost**: ~$3/month
  - Logs: $0.50/GB ingested + $0.03/GB storage
  - Metrics: First 10 custom metrics free
  - Alarms: First 10 alarms free
  - Dashboard: First 3 free
- **Free Tier**: 5GB logs, 10 metrics, 10 alarms, 3 dashboards

#### **CloudWatch Agent** ✅
- **Purpose**: Collect system metrics from EC2
- **Metrics Collected**: CPU, memory, disk, network
- **Cost**: Included in CloudWatch costs

### Notifications

#### **SNS (Simple Notification Service)** ✅
- **Purpose**: Email notifications for alarms
- **Topics**: CareFlowAI-Alarms
- **Cost**: First 1,000 email notifications free, then $2 per 100,000

### Infrastructure as Code

#### **CloudFormation** ✅
- **Purpose**: Infrastructure deployment and management
- **Stacks**:
  - VPC, Security Groups, EC2, S3, CloudFront
  - ALB, API Gateway, Auto Scaling Group
  - CloudWatch monitoring
- **Cost**: Free (pay only for resources created)

### Systems Management

#### **Systems Manager (SSM)** ✅
- **Features Used**:
  - Parameter Store (configuration)
  - Session Manager (secure shell access)
  - AMI parameter references
- **Cost**: Free for standard parameters and session manager

### External Services

#### **Google Gemini AI** ✅ (Third-party, not AWS)
- **Purpose**: AI-powered medical report analysis
- **API Calls**: From EC2 instances
- **Cost**: Free tier available
- **Upgrade**: Pay-as-you-go pricing

---

## Services NOT Used

### Compute Services

#### **EKS (Elastic Kubernetes Service)** ❌
- **Reason**: EC2 + Auto Scaling is simpler and cheaper
- **Cost Savings**: $73/month (control plane) + worker nodes
- **Alternative**: EC2 with Auto Scaling Group
- **When to Consider**: If you need Kubernetes features, multi-cluster management

#### **Lambda** ❌
- **Reason**: Not currently needed
- **Note**: IAM policies allow Lambda invocation for future use
- **When to Consider**: Event-driven processing, serverless architecture

#### **Fargate** ❌
- **Reason**: Not using containers
- **When to Consider**: Serverless container hosting

### Database Services

#### **DocumentDB (MongoDB-compatible)** ❌
- **Reason**: MongoDB Atlas provides free tier
- **Cost Savings**: ~$200/month
- **Atlas Benefits**:
  - Free M0 tier (512MB)
  - Easier setup
  - No VPC peering required
  - Better for development
- **When to Consider**: Production workloads requiring VPC integration, compliance requirements

#### **RDS (Relational Database Service)** ❌
- **Reason**: Using MongoDB (NoSQL)
- **Cost**: Starting at $15/month (db.t3.micro)

#### **DynamoDB** ❌
- **Reason**: Using MongoDB Atlas
- **Cost**: Pay-per-request or provisioned capacity

### Container Services

#### **ECR (Elastic Container Registry)** ❌
- **Reason**: Not using containers
- **Cost**: $0.10/GB-month storage
- **When to Consider**: Docker-based deployments

#### **ECS (Elastic Container Service)** ❌
- **Reason**: Not using containers
- **When to Consider**: Container orchestration without Kubernetes

### Networking Services

#### **NAT Gateway** ❌
- **Reason**: Using public subnets only
- **Cost Savings**: $32.40/month per gateway + data processing
- **When to Consider**: Private subnet architecture

#### **Route 53** ❌
- **Reason**: Using default CloudFront/ALB domains
- **Cost**: $0.50/hosted zone + $0.40/million queries
- **When to Consider**: Custom domain configuration

#### **VPC Peering** ❌
- **Reason**: No multi-VPC architecture
- **When to Consider**: Connecting to other VPCs, DocumentDB

### Storage Services

#### **EFS (Elastic File System)** ❌
- **Reason**: No shared file system needed
- **Cost**: $0.30/GB-month
- **When to Consider**: Shared storage across multiple EC2 instances

#### **FSx** ❌
- **Reason**: No Windows/Lustre requirements
- **Cost**: Starting at $0.013/GB-hour

### Security Services

#### **WAF (Web Application Firewall)** ❌
- **Reason**: Basic security sufficient for development
- **Cost**: $5/month + $1/million requests
- **When to Consider**: Production environments, DDoS protection

#### **Shield** ❌
- **Reason**: Not needed at current scale
- **Cost**: Standard (free), Advanced ($3,000/month)

#### **Secrets Manager** ❌
- **Reason**: Using environment variables
- **Cost**: $0.40/secret/month + $0.05/10,000 API calls
- **Alternative**: SSM Parameter Store (free for standard parameters)
- **When to Consider**: Automatic secret rotation, auditing

### Analytics Services

#### **Kinesis** ❌
- **Reason**: No real-time streaming needed
- **Cost**: $0.015/shard-hour

#### **Athena** ❌
- **Reason**: No SQL queries on S3 data
- **Cost**: $5/TB scanned

### Machine Learning Services

#### **SageMaker** ❌
- **Reason**: Using Google Gemini AI
- **Cost**: Instance costs starting at $0.05/hour
- **When to Consider**: Custom ML models, model training

#### **Comprehend Medical** ❌
- **Reason**: Using Gemini AI for NLP
- **Cost**: $0.01/unit (100 characters)

### Other Services

#### **ElastiCache (Redis/Memcached)** ❌
- **Reason**: No caching layer needed yet
- **Cost**: Starting at $0.034/hour (cache.t3.micro)
- **When to Consider**: Session storage, API response caching

#### **SQS (Simple Queue Service)** ❌
- **Reason**: No message queuing needed
- **Cost**: First 1M requests free, then $0.40/million

#### **Step Functions** ❌
- **Reason**: No complex workflows
- **Cost**: $25 per million state transitions

---

## Cost Comparison

### Current Architecture (Monthly Costs)

#### Simple Deployment (Development)
```
EC2 t2.micro × 1:              $8.50
EBS 30GB:                      $2.40
Elastic IP:                    $0.00  (attached)
S3 (frontend):                 $0.50
CloudFront:                    $1.00
CloudWatch:                    $1.00
Data Transfer:                 $2.00
────────────────────────────────────
TOTAL:                        ~$15.40/month

With Free Tier (first 12 months):
EC2 (750 hours):               $0.00
EBS:                           $0.00
CloudFront (1TB):              $0.00
────────────────────────────────────
TOTAL WITH FREE TIER:         ~$3.50/month
```

#### Production Deployment (with ALB + API Gateway)
```
EC2 t2.micro × 1-3:           $8.50 - $25.50
EBS 30GB × 1-3:               $2.40 - $7.20
ALB:                          $16.20
ALB Data Processing:          $2.00
API Gateway (1M requests):    $1.00
CloudFront:                   $1.00
S3:                           $0.50
CloudWatch:                   $3.00
Data Transfer:                $5.00
VPC:                          $0.00
────────────────────────────────────
TOTAL:                        ~$39.60 - $61.40/month

Average with 2 instances:     ~$50/month
```

### Alternative Architecture Costs

#### With EKS + DocumentDB (Production-Grade)
```
EKS Control Plane:            $73.00
EC2 for EKS Workers × 2:      $30.00
EBS for Workers:              $4.80
DocumentDB (1 instance):      $200.00
ALB:                          $16.20
S3:                           $0.50
CloudWatch:                   $5.00
Data Transfer:                $10.00
────────────────────────────────────
TOTAL:                        ~$339.50/month
```

#### With Lambda + DynamoDB (Serverless)
```
API Gateway:                  $3.50  (for 1M requests)
Lambda:                       $5.00  (for 1M requests, 512MB, 1s)
DynamoDB:                     $25.00 (on-demand)
S3:                           $0.50
CloudFront:                   $1.00
CloudWatch:                   $2.00
────────────────────────────────────
TOTAL:                        ~$37/month (low traffic)
                              ~$100+/month (high traffic)
```

### Cost Savings Summary

| Architecture | Monthly Cost | Savings vs EKS | Notes |
|--------------|--------------|----------------|-------|
| **Current (Simple)** | $15 | $325 (96%) | Development/Testing |
| **Current (Production)** | $50 | $290 (85%) | Production with ALB |
| **EKS + DocumentDB** | $340 | - | Enterprise scale |
| **Serverless** | $37-$100+ | Variable | Pay-per-use |

**Best Cost Savings: Using current architecture saves ~$280-$325/month compared to EKS**

---

## Architecture Decisions

### Why EC2 + Auto Scaling Instead of EKS?

| Factor | EC2 + ASG | EKS | Winner |
|--------|-----------|-----|--------|
| **Cost** | $8-25/month | $73+/month | EC2 |
| **Complexity** | Low | High | EC2 |
| **Setup Time** | 20 min | 2-3 hours | EC2 |
| **Learning Curve** | Low | Steep | EC2 |
| **Scaling** | Good | Excellent | EKS |
| **Portability** | Low | High | EKS |

**Decision**: EC2 + ASG is sufficient for current scale and requirements.

### Why MongoDB Atlas Instead of DocumentDB?

| Factor | MongoDB Atlas | DocumentDB | Winner |
|--------|---------------|------------|--------|
| **Cost** | $0 (M0 tier) | $200/month | Atlas |
| **Setup** | 5 minutes | 30 minutes | Atlas |
| **Management** | Fully managed | AWS managed | Atlas |
| **Features** | Full MongoDB | Compatible | Atlas |
| **VPC Integration** | Internet | VPC peering | DocumentDB |
| **Backup** | Automatic | Automatic | Tie |

**Decision**: Atlas free tier is perfect for development and small production workloads.

### Why API Gateway + ALB Instead of Direct ALB?

| Feature | API Gateway + ALB | Direct ALB | Benefit |
|---------|-------------------|------------|---------|
| **Rate Limiting** | Built-in | Manual | API GW |
| **API Management** | Yes | No | API GW |
| **Monitoring** | Enhanced | Basic | API GW |
| **Cost** | +$1/month | $0 | ALB |
| **CORS** | Built-in | Manual | API GW |
| **Caching** | Built-in | No | API GW |

**Decision**: API Gateway adds valuable features for minimal cost.

---

## Free Tier Benefits

### First 12 Months (AWS Free Tier)

| Service | Free Tier Benefit | Value |
|---------|-------------------|-------|
| EC2 t2.micro | 750 hours/month | ~$8.50/month |
| EBS | 30GB | ~$2.40/month |
| S3 | 5GB storage, 20K GET, 2K PUT | ~$0.50/month |
| CloudFront | 1TB transfer, 10M requests | ~$50/month (if used) |
| API Gateway | 1M requests | ~$1/month |
| CloudWatch | 10 metrics, 10 alarms, 5GB logs | ~$3/month |
| **TOTAL SAVINGS** | | **~$65/month** |

### Always Free (Beyond 12 Months)

| Service | Always Free Benefit |
|---------|---------------------|
| VPC | All features |
| IAM | All features |
| CloudFormation | All features |
| Security Groups | All features |
| Auto Scaling | All features |
| SSM Parameter Store | 10,000 standard parameters |
| SNS | 1,000 email notifications |
| CloudWatch | 10 alarms, 10 metrics |

---

## Cost Optimization Tips

### Immediate Actions

1. **Stop Instances When Not in Use**
   ```bash
   # Stop EC2
   aws ec2 stop-instances --instance-ids i-xxxxx

   # Cost: $0/hour (vs $0.0116/hour running)
   # Savings: ~$8.50/month per instance
   ```

2. **Set CloudWatch Log Retention**
   ```bash
   aws logs put-retention-policy \
     --log-group-name /careflowai/backend \
     --retention-in-days 7

   # Savings: ~$1-2/month
   ```

3. **Use S3 Lifecycle Policies**
   ```bash
   # Delete old logs after 30 days
   # Savings: ~$0.50-1/month
   ```

### Medium-Term Actions

4. **Reserved Instances** (1-year commitment)
   - EC2 t2.micro: $3.50/month (vs $8.50/month)
   - Savings: 59% ($5/month per instance)
   - Best for: Predictable production workloads

5. **Savings Plans** (flexible commitment)
   - Compute: 66% savings
   - EC2 Instance: 72% savings
   - Best for: Variable workloads

6. **Schedule Auto Scaling**
   ```bash
   # Scale down during off-hours (8 PM - 8 AM)
   aws autoscaling put-scheduled-action \
     --auto-scaling-group-name CareFlowAI-Backend-ASG \
     --scheduled-action-name scale-down-evening \
     --recurrence "0 20 * * *" \
     --desired-capacity 0

   # Savings: ~$5-10/month
   ```

### Long-Term Actions

7. **Migrate to Spot Instances** (for non-production)
   - Cost: 70-90% cheaper than on-demand
   - Savings: ~$6-7/month per instance
   - Risk: Can be terminated with 2-min warning

8. **Optimize Instance Sizing**
   ```bash
   # Monitor actual usage
   # Right-size based on CloudWatch metrics
   # Potential savings: 20-30%
   ```

9. **Enable Cost Anomaly Detection**
   ```bash
   aws ce create-anomaly-monitor \
     --anomaly-monitor '{
       "MonitorName": "CareFlowAI-Monitor",
       "MonitorType": "CUSTOM"
     }'
   ```

### Cost Monitoring

```bash
# Set up budget alerts
aws budgets create-budget \
  --account-id YOUR_ACCOUNT_ID \
  --budget '{
    "BudgetName": "Monthly-Budget",
    "BudgetLimit": {"Amount": "50", "Unit": "USD"},
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST"
  }' \
  --notifications-with-subscribers '{
    "Notification": {
      "NotificationType": "ACTUAL",
      "ComparisonOperator": "GREATER_THAN",
      "Threshold": 80
    },
    "Subscribers": [{
      "SubscriptionType": "EMAIL",
      "Address": "your@email.com"
    }]
  }'
```

---

## Scaling Cost Projections

### Traffic Growth Scenarios

#### Low Traffic (Current)
- **Requests**: 10K/day
- **Users**: 100 concurrent
- **Instances**: 1 EC2
- **Cost**: ~$15/month (simple) or ~$40/month (production)

#### Medium Traffic
- **Requests**: 100K/day
- **Users**: 1,000 concurrent
- **Instances**: 2-3 EC2
- **API Gateway**: Still within free tier (3M requests/month)
- **Cost**: ~$55-70/month
- **Scaling**: Auto Scaling handles automatically

#### High Traffic
- **Requests**: 1M/day (30M/month)
- **Users**: 10,000 concurrent
- **Instances**: 5-10 EC2 (need to increase max)
- **API Gateway**: $30/month (30M requests)
- **ALB Data Processing**: ~$20/month
- **CloudFront**: ~$50/month (5TB transfer)
- **Cost**: ~$200-300/month
- **Recommendation**: Consider caching, CDN optimization

#### Very High Traffic (Enterprise)
- **Requests**: 10M+/day
- **Users**: 100,000+ concurrent
- **Architecture Change Needed**:
  - ElastiCache for caching
  - DocumentDB for better VPC integration
  - Multi-region deployment
  - WAF for security
- **Cost**: ~$1,000+/month
- **Recommendation**: Migrate to EKS + DocumentDB

### Cost Per User

| Scale | Users | Cost/Month | Cost/User |
|-------|-------|------------|-----------|
| **Small** | 100 | $40 | $0.40 |
| **Medium** | 1,000 | $70 | $0.07 |
| **Large** | 10,000 | $250 | $0.025 |
| **Enterprise** | 100,000+ | $1,000+ | $0.01 |

**Observation**: Cost per user decreases with scale (economies of scale).

---

## Summary

### Current Architecture Benefits

✅ **Cost-Effective**: ~$40-50/month for production
✅ **Simple**: Easy to deploy and maintain
✅ **Scalable**: Can handle 100K requests/day
✅ **Reliable**: Multi-AZ with auto-scaling
✅ **Monitored**: CloudWatch logs and alarms
✅ **Free Tier**: Significant savings first year

### When to Consider Migration

⏭ **To EKS**: When you need Kubernetes features, multi-cluster
⏭ **To Serverless**: When traffic is very spiky, unpredictable
⏭ **To DocumentDB**: When you need VPC integration, compliance
⏭ **To Multi-Region**: When you need global low latency

### Cost Optimization Priority

1. ✅ Use free tier benefits (first 12 months)
2. ✅ Stop resources when not in use
3. ✅ Set log retention policies
4. ⏭ Reserved Instances (after 12 months)
5. ⏭ Implement caching
6. ⏭ Right-size instances based on metrics

---

**For deployment instructions, see [Deployment_order_and_commands.md](./Deployment_order_and_commands.md)**

**For architecture details, see [Deployment_architecture.md](./Deployment_architecture.md)**
