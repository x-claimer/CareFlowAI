# CareFlowAI AWS Architecture

Complete architecture documentation for CareFlowAI AWS deployment.

## Architecture Diagrams

### Simple Architecture (Development/Testing)

```
┌─────────────────────────────────────────────────┐
│                    User                          │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│         CloudFront CDN (Frontend)                │
│         S3 Bucket: React App                     │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│         EC2 Instance (t2.micro)                  │
│         - FastAPI Backend (Port 8000)            │
│         - Nginx Reverse Proxy                    │
│         - Ubuntu 22.04                           │
└──────────────────┬──────────────────────────────┘
                   │
                   ├────────────────┬───────────────┐
                   ▼                ▼               ▼
           ┌──────────────┐  ┌──────────┐  ┌─────────────┐
           │ MongoDB      │  │ Gemini   │  │ CloudWatch  │
           │ Atlas        │  │ AI API   │  │ Logs        │
           └──────────────┘  └──────────┘  └─────────────┘
```

### Production Architecture (with API Gateway & ALB)

```
┌─────────────────────────────────────────────────┐
│                    User                          │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│         CloudFront CDN (Frontend)                │
│         S3 Bucket: React App                     │
│         - HTTPS enabled                          │
│         - Global distribution                    │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│         API Gateway (HTTP API)                   │
│         - Rate limiting: 500 req/s               │
│         - CORS enabled                           │
│         - CloudWatch logging                     │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│         VPC Link (Private Connection)            │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│    Application Load Balancer (ALB)               │
│    - Health checks: /health                      │
│    - Port 80 (HTTP)                              │
│    - Sticky sessions enabled                     │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│         Target Group                             │
│         - Health check interval: 30s             │
│         - Unhealthy threshold: 3                 │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│    Auto Scaling Group (1-3 instances)           │
│    - Instance type: t2.micro                     │
│    - Scale on: CPU (70%), Requests (1000)       │
│    - Health check type: ELB                      │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│         EC2 Instances (t2.micro)                 │
│         - Ubuntu 22.04                           │
│         - FastAPI Backend (Port 8000)            │
│         - Nginx Reverse Proxy                    │
│         - CloudWatch Agent                       │
│         - 30GB gp3 EBS (encrypted)               │
└──────────────────┬──────────────────────────────┘
                   │
                   ├──────────────┬─────────────────┐
                   ▼              ▼                 ▼
           ┌──────────────┐  ┌──────────┐  ┌─────────────┐
           │ MongoDB      │  │ Gemini   │  │ CloudWatch  │
           │ Atlas        │  │ AI API   │  │ Logs/       │
           │              │  │          │  │ Metrics     │
           └──────────────┘  └──────────┘  └─────────────┘
```

## Network Architecture

### VPC Configuration

```
VPC: 10.0.0.0/16
│
├── Public Subnet 1 (10.0.1.0/24) - us-east-1a
│   ├── EC2 Instances
│   ├── ALB
│   └── NAT Gateway (if using private subnets)
│
├── Public Subnet 2 (10.0.2.0/24) - us-east-1b
│   ├── EC2 Instances
│   ├── ALB
│   └── NAT Gateway (if using private subnets)
│
├── Internet Gateway
│   └── Routes to 0.0.0.0/0
│
└── Security Groups
    ├── Backend SG (EC2)
    │   ├── Inbound: 22 (SSH), 8000 (FastAPI), 80 (HTTP)
    │   └── Outbound: All
    │
    ├── ALB SG
    │   ├── Inbound: 80 (HTTP), 443 (HTTPS)
    │   └── Outbound: To Backend SG on port 8000
    │
    └── VPC Link SG
        ├── Inbound: From API Gateway
        └── Outbound: To ALB
```

## Infrastructure Components

### 1. VPC and Networking

**Components:**
- VPC with CIDR 10.0.0.0/16
- 2 Public Subnets across 2 Availability Zones
- Internet Gateway
- Route Tables
- Security Groups

**Purpose:**
- Network isolation
- High availability
- Traffic control

### 2. Compute (EC2)

**Specifications:**
- Instance Type: t2.micro (1 vCPU, 1GB RAM)
- OS: Ubuntu 22.04 LTS
- Storage: 30GB gp3 EBS (encrypted)
- Elastic IP: Static public IP

**Installed Software:**
- Python 3.10+
- FastAPI + Uvicorn
- Nginx (reverse proxy)
- CloudWatch Agent
- Git

**Purpose:**
- Backend API hosting
- Request processing
- AI integration

### 3. Auto Scaling Group (Optional)

**Configuration:**
- Min: 1 instance
- Max: 3 instances
- Desired: 1 instance
- Instance type: t2.micro only

**Scaling Policies:**
- CPU-based: Target 70% utilization
- Request-based: Target 1000 requests/target

**Health Checks:**
- Type: ELB
- Path: /health
- Interval: 30 seconds
- Timeout: 10 seconds

### 4. Application Load Balancer

**Configuration:**
- Type: Application Load Balancer
- Scheme: Internet-facing
- Listeners: HTTP (port 80)
- Target Group: EC2 instances on port 8000

**Features:**
- Health checks
- Sticky sessions (24 hours)
- Connection draining (30 seconds)
- Cross-zone load balancing

### 5. API Gateway

**Configuration:**
- Type: HTTP API
- Protocol: HTTPS
- VPC Link: Private connection to ALB
- CORS: Enabled for all origins

**Routes:**
- `$default` - Catch-all
- `GET /health` - Health check
- `ANY /api/{proxy+}` - API endpoints
- `GET /docs` - API documentation

**Features:**
- Rate limiting: 500 req/sec
- Burst limit: 1000 requests
- Access logging
- CloudWatch integration

### 6. Storage (S3 & CloudFront)

**S3 Configuration:**
- Bucket: `{AccountId}-careflowai-frontend`
- Website hosting enabled
- Public read access
- Versioning: Suspended

**CloudFront Configuration:**
- Origin: S3 bucket
- Protocol: HTTPS redirect
- Compression: Enabled
- Custom error pages for React Router
- Price class: 100 (North America & Europe)

### 7. Monitoring (CloudWatch)

**Log Groups:**
- `/careflowai/backend` - Application logs (30-day retention)
- `/aws/apigateway/CareFlowAI` - API Gateway logs (7-day retention)

**Custom Metrics:**
- CPU usage
- Memory usage (MEM_USED)
- Disk usage (DISK_USED)
- TCP connections

**Alarms:**
- ALB high latency (>1 second)
- Unhealthy hosts
- 5XX errors (>10 in 5 min)
- High CPU (>80%)
- Low instance count (<2)
- High memory (>85%)
- High disk usage (>80%)

**Dashboard Widgets:**
- Request metrics
- Response times (avg, P99)
- Target health
- ASG instance counts
- CPU utilization
- Memory/disk usage
- Error logs
- Connection metrics

### 8. IAM Roles and Policies

**EC2 Instance Role:**
- CloudWatchAgentServerPolicy (managed)
- AmazonSSMManagedInstanceCore (managed)
- Custom policies:
  - CloudWatch Logs (create/put)
  - SSM Parameter Store (read)
  - Lambda Invoke (future use)

**Purpose:**
- Secure access to AWS services
- No long-term credentials needed
- Least privilege principle

## Data Flow

### User Request Flow

1. **User** opens frontend in browser
2. **CloudFront** serves React app from S3
3. User action triggers **API call**
4. **API Gateway** receives request
5. **VPC Link** forwards to private ALB
6. **ALB** distributes to healthy EC2 instance
7. **EC2** processes request via FastAPI
8. **Backend** queries MongoDB Atlas
9. **Backend** calls Gemini AI (if needed)
10. **Response** flows back through chain
11. **CloudFront** caches static assets

### Health Check Flow

```
ALB → Target Group → EC2 Instance (port 8000)
                         ↓
                    GET /health
                         ↓
                    FastAPI Handler
                         ↓
                    MongoDB Connection Test
                         ↓
                    Return 200 OK
```

### Scaling Flow

```
CloudWatch Metrics
    ↓
CPU > 70% OR Requests > 1000
    ↓
Auto Scaling Policy Triggered
    ↓
Launch New Instance from Template
    ↓
Instance Initialization (UserData)
    ↓
Health Check Passes
    ↓
Added to Target Group
    ↓
Receives Traffic from ALB
```

## Security Architecture

### Network Security

**Layers:**
1. **CloudFront**: DDoS protection, HTTPS
2. **API Gateway**: Rate limiting, throttling
3. **VPC**: Network isolation
4. **Security Groups**: Firewall rules
5. **NACL**: Subnet-level firewall (default)

**Traffic Flow:**
- Internet → CloudFront (HTTPS) → User
- Internet → API Gateway (HTTPS) → VPC Link → ALB (HTTP) → EC2
- EC2 → Internet (for MongoDB Atlas, Gemini AI)

### Data Security

**Encryption:**
- ✅ **In Transit**: CloudFront HTTPS, API Gateway HTTPS
- ✅ **At Rest**: EBS encryption
- ✅ **Database**: MongoDB Atlas encryption
- ⚠️ **ALB to EC2**: HTTP (can enable HTTPS with ACM certificate)

**Secrets Management:**
- Environment variables in .env file
- SSM Parameter Store (future enhancement)
- No hardcoded credentials

### Access Control

**IAM:**
- Roles for EC2 instances
- Minimal permissions
- No access keys stored

**SSH:**
- Key-based authentication only
- Restricted to specific IPs (recommended)
- Can use Session Manager instead

### Monitoring & Compliance

**Logging:**
- All API requests logged
- Application logs in CloudWatch
- ALB access logs (optional)
- VPC Flow Logs (optional)

**Alerting:**
- Security group changes
- Failed login attempts
- Unusual traffic patterns
- Resource access patterns

## High Availability

### Multi-AZ Deployment

- **Subnets**: 2 AZs (us-east-1a, us-east-1b)
- **ALB**: Automatically spans AZs
- **ASG**: Launches instances across AZs
- **Benefit**: Survives single AZ failure

### Health Checks

- **ALB Health Checks**: Every 30 seconds
- **ASG Health Checks**: Via ALB status
- **Automatic Recovery**: Unhealthy instances replaced

### Scaling

- **Horizontal**: Add more instances (ASG)
- **Vertical**: Change instance type (requires downtime)
- **Auto Scaling**: Based on CPU and requests

## Disaster Recovery

### Backup Strategy

**MongoDB Atlas:**
- Automatic backups
- Point-in-time recovery
- Managed by Atlas

**Frontend (S3):**
- Version control in Git
- Can redeploy from source

**Backend (EC2):**
- Code in Git repository
- Infrastructure as Code (CloudFormation)
- Can recreate from templates

### Recovery Procedures

**Complete Failure:**
1. Run cleanup script
2. Redeploy infrastructure
3. Restore MongoDB from backup
4. Redeploy applications

**Partial Failure:**
- EC2 failure: ASG auto-replaces
- ALB failure: AWS manages redundancy
- AZ failure: Traffic routes to healthy AZ

## Performance Optimization

### Caching

- **CloudFront**: Static assets cached globally
- **API Gateway**: Response caching (optional)
- **Application**: In-memory caching (optional)

### Connection Pooling

- **MongoDB**: Connection pool in FastAPI
- **HTTP**: Keep-alive connections

### Content Delivery

- **CloudFront**: Global edge locations
- **Compression**: Enabled for CloudFront
- **Minification**: Build-time optimization

## Cost Optimization

### Current Setup

- **t2.micro**: Free tier eligible (750 hours/month)
- **Auto Scaling**: Only pay for what you use
- **CloudFront**: Free tier (1TB transfer)
- **API Gateway**: Free tier (1M requests)
- **MongoDB Atlas**: Free M0 cluster

### Optimization Tips

1. Stop instances when not in use
2. Use Reserved Instances for production
3. Enable S3 Intelligent-Tiering
4. Set CloudWatch log retention limits
5. Schedule ASG for off-hours scaling

## Monitoring & Observability

### Key Metrics

**Application:**
- Request count
- Response time
- Error rate
- Active users

**Infrastructure:**
- CPU utilization
- Memory usage
- Disk usage
- Network throughput

**Business:**
- API usage
- Feature usage
- User activity

### Alerting Strategy

**Critical (Immediate):**
- Service down
- 5XX errors spike
- All instances unhealthy

**Warning (15 min):**
- High latency
- High resource usage
- Single instance unhealthy

**Info (Daily):**
- Cost anomalies
- Usage patterns
- Security events

---

This architecture provides a scalable, secure, and cost-effective solution for the CareFlowAI application.
