# Docker and Kubernetes Setup Guide for CareFlowAI

This guide provides instructions for running CareFlowAI locally using Docker Compose or Kubernetes.

## Prerequisites

### For Docker Compose
- Docker Desktop (version 20.10 or higher)
- Docker Compose (version 2.0 or higher)

### For Kubernetes
- Docker Desktop with Kubernetes enabled, OR
- Minikube (version 1.30 or higher), OR
- Kind (Kubernetes in Docker) - **Recommended for local K8s**
- kubectl CLI tool

## Project Structure

```
CareFlowAI/
├── backend/
│   ├── Dockerfile
│   └── .dockerignore
├── frontend/
│   ├── Dockerfile
│   ├── nginx.conf
│   └── .dockerignore
├── docker-compose.yml
└── k8s/
    ├── namespace.yaml
    ├── secrets.yaml
    ├── configmap.yaml
    ├── mongodb-pv-pvc.yaml
    ├── mongodb-deployment.yaml
    ├── mongodb-service.yaml
    ├── backend-deployment.yaml
    ├── backend-service.yaml
    ├── frontend-deployment.yaml
    └── frontend-service.yaml
```

---

## Setup Steps

### Step 1: Build Docker Images

First, build the Docker images for both backend and frontend:

```bash
# Navigate to project root
cd CareFlowAI

# Build backend image
docker build -t careflowai-backend:latest ./backend

# Build frontend image
docker build -t careflowai-frontend:latest ./frontend

# Verify images are created
docker images | grep careflowai
```

---

## Option 1: Docker Compose (Recommended for Quick Local Development)

### Step 1: Start Services with Docker Compose

```bash
# Navigate to project root
cd CareFlowAI

# Start all services (images already built above)
docker-compose up

# Or run in detached mode (background)
docker-compose up -d
```

### Step 2: Access the Application

- **Frontend**: http://localhost:5173
- **Backend API**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs
- **MongoDB**: localhost:27017

### Step 3: View Logs

```bash
# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f mongodb
```

### Step 4: Stop Services

```bash
# Stop services
docker-compose down

# Stop and remove volumes (will delete database data)
docker-compose down -v
```

### Useful Docker Compose Commands

```bash
# Rebuild a specific service
docker-compose build backend

# Restart a specific service
docker-compose restart backend

# Check service status
docker-compose ps

# Execute command in running container
docker-compose exec backend bash
docker-compose exec mongodb mongosh
```

---

## Option 2: Kubernetes with Kind (Recommended for K8s Development)

### Prerequisites: Install Kind

```bash
# Windows (using PowerShell with Chocolatey)
choco install kind

# macOS (using Homebrew)
brew install kind

# Linux
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Verify installation
kind version
```

### Step 1: Create Kind Cluster

```bash
# Create a Kind cluster with port mappings
cat <<EOF | kind create cluster --name careflowai --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 30080
    protocol: TCP
  - containerPort: 30800
    hostPort: 30800
    protocol: TCP
EOF

# Verify cluster is running
kind get clusters
kubectl cluster-info --context kind-careflowai
```

### Step 2: Load Docker Images into Kind

Since Kind runs Kubernetes in Docker, you need to load your images into the Kind cluster:

```bash
# Load backend image into Kind
kind load docker-image careflowai-backend:latest --name careflowai

# Load frontend image into Kind
kind load docker-image careflowai-frontend:latest --name careflowai

# Verify images are loaded
docker exec -it careflowai-control-plane crictl images | grep careflowai
```

### Step 3: Deploy to Kubernetes

```bash
# Navigate to project root
cd CareFlowAI

# Create namespace
kubectl apply -f k8s/namespace.yaml

# Create secrets and configmaps
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/configmap.yaml

# Create MongoDB persistent storage
kubectl apply -f k8s/mongodb-pv-pvc.yaml

# Deploy MongoDB
kubectl apply -f k8s/mongodb-deployment.yaml
kubectl apply -f k8s/mongodb-service.yaml

# Wait for MongoDB to be ready
kubectl wait --for=condition=ready pod -l app=mongodb -n careflowai --timeout=120s

# Deploy Backend
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/backend-service.yaml

# Wait for Backend to be ready
kubectl wait --for=condition=ready pod -l app=backend -n careflowai --timeout=120s

# Deploy Frontend
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/frontend-service.yaml
```

### Step 4: Access the Application

```bash
# Frontend will be available at:
# http://localhost:30080

# You can also use port-forward if needed
kubectl port-forward service/frontend-service 8080:80 -n careflowai
# Then access at http://localhost:8080
```

### Step 5: Monitor Deployment

```bash
# Check all resources in namespace
kubectl get all -n careflowai

# Check pod status
kubectl get pods -n careflowai

# Watch pod status in real-time
kubectl get pods -n careflowai -w

# Check logs
kubectl logs -f deployment/backend -n careflowai
kubectl logs -f deployment/frontend -n careflowai
kubectl logs -f deployment/mongodb -n careflowai

# Describe a pod (for troubleshooting)
kubectl describe pod <pod-name> -n careflowai
```

### Step 6: Update Application

When you make changes to code:

```bash
# Rebuild the Docker image
docker build -t careflowai-backend:latest ./backend

# Load updated image into Kind
kind load docker-image careflowai-backend:latest --name careflowai

# Restart deployment to use new image
kubectl rollout restart deployment/backend -n careflowai

# Check rollout status
kubectl rollout status deployment/backend -n careflowai
```

### Step 7: Clean Up Kind Cluster

```bash
# Delete all resources in namespace (but keep cluster)
kubectl delete namespace careflowai

# Or delete the entire Kind cluster
kind delete cluster --name careflowai
```

---

## Option 3: Kubernetes with Docker Desktop

### Prerequisites Setup

1. Open Docker Desktop
2. Go to Settings → Kubernetes
3. Enable Kubernetes
4. Click "Apply & Restart"

### Step 1: Deploy to Kubernetes

Follow the same deployment steps as Kind (Step 3 from Option 2), but you don't need to load images since Docker Desktop uses your local Docker images directly.

### Step 2: Access the Application

```bash
# Frontend will be available at:
# http://localhost:30080
```

---

## Option 4: Kubernetes with Minikube

### Prerequisites Setup

```bash
# Start Minikube
minikube start --cpus=4 --memory=8192

# Enable required addons
minikube addons enable ingress
```

### Step 1: Build Images in Minikube

```bash
# Point Docker CLI to Minikube's Docker daemon
eval $(minikube docker-env)

# Build backend image
docker build -t careflowai-backend:latest ./backend

# Build frontend image
docker build -t careflowai-frontend:latest ./frontend
```

### Step 2: Deploy to Kubernetes

Follow the same deployment steps as Kind (Step 3 from Option 2).

### Step 3: Access the Application

```bash
# Get Minikube IP
minikube ip

# Access application at:
# http://<minikube-ip>:30080

# Or use Minikube service command to open in browser
minikube service frontend-service -n careflowai
```

### Step 4: Clean Up

```bash
# Delete namespace
kubectl delete namespace careflowai

# Stop Minikube
minikube stop

# Or delete Minikube cluster entirely
minikube delete
```

---

## Troubleshooting

### Docker Compose Issues

**Problem: Port already in use**
```bash
# Find process using port 5173 or 8000
# Windows:
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# Linux/Mac:
lsof -i :8000
kill -9 <PID>

# Or change ports in docker-compose.yml
```

**Problem: MongoDB connection failed**
```bash
# Check MongoDB logs
docker-compose logs mongodb

# Restart MongoDB
docker-compose restart mongodb
```

**Problem: Backend can't connect to MongoDB**
- Ensure MongoDB is healthy: `docker-compose ps`
- Check environment variables in docker-compose.yml
- Verify MongoDB connection string

### Kubernetes Issues

**Problem: ImagePullBackOff error**
```bash
# Check if images exist locally
docker images | grep careflowai

# If using Kind, load images into cluster
kind load docker-image careflowai-backend:latest --name careflowai

# If using Minikube, ensure you built images in Minikube's Docker
eval $(minikube docker-env)
docker build -t careflowai-backend:latest ./backend
```

**Problem: CrashLoopBackOff**
```bash
# Check pod logs
kubectl logs <pod-name> -n careflowai

# Check pod events
kubectl describe pod <pod-name> -n careflowai

# Common causes:
# - MongoDB not ready yet
# - Environment variables incorrect
# - Application crash on startup
```

**Problem: Pods stuck in Pending state**
```bash
# Check events
kubectl describe pod <pod-name> -n careflowai

# Check if PersistentVolume is bound
kubectl get pv,pvc -n careflowai

# Common causes:
# - Insufficient resources
# - PV/PVC not bound
# - Node selector issues
```

**Problem: Can't access application on Kind**
```bash
# Verify port mappings were set correctly when creating cluster
kubectl get svc -n careflowai

# Check if pods are ready
kubectl get pods -n careflowai

# Try port-forward as alternative
kubectl port-forward service/frontend-service 8080:80 -n careflowai
# Then access at http://localhost:8080
```

**Problem: Kind cluster won't start**
```bash
# Check Docker is running
docker ps

# Delete and recreate cluster
kind delete cluster --name careflowai
# Then recreate with the cluster config
```

---

## Useful Kind Commands

```bash
# List all Kind clusters
kind get clusters

# Get cluster info
kubectl cluster-info --context kind-careflowai

# View cluster nodes
kubectl get nodes

# Load image into cluster
kind load docker-image <image-name>:tag --name careflowai

# Export cluster logs (for debugging)
kind export logs --name careflowai

# Delete cluster
kind delete cluster --name careflowai
```

---

## Security Notes

⚠️ **IMPORTANT**: The default configurations are for local development only!

Before deploying to production:

1. **Change default secrets** in `k8s/secrets.yaml`:
   - MongoDB username and password
   - JWT secret key

2. **Use proper secret management**:
   - Use Kubernetes Secrets with encryption at rest
   - Consider using external secret management (HashiCorp Vault, AWS Secrets Manager)

3. **Update MongoDB** to use authentication in production

4. **Configure HTTPS** with proper TLS certificates

5. **Set resource limits** based on your infrastructure

6. **Enable monitoring and logging** (Prometheus, Grafana, ELK stack)

---

## Comparison: Which Option to Choose?

| Feature | Docker Compose | Kind | Docker Desktop K8s | Minikube |
|---------|---------------|------|-------------------|----------|
| **Setup Speed** | Fast |  Fast |  Medium |  Medium |
| **Resource Usage** |  Low |  Medium |  Medium |  High |
| **K8s Features** | ❌ None |  Full |  Full |  Full |
| **Multi-cluster** | ❌ No |  Easy | ❌ No |  Possible |
| **CI/CD Testing** |  Basic |  Excellent |  Good |  Good |
| **Best For** | Quick dev/testing | K8s learning & CI | General K8s dev | K8s dev with addons |

**Recommendation:**
- **Docker Compose**: Quick testing, simple development
- **Kind**: Best for learning Kubernetes, CI/CD pipelines, multi-cluster testing
- **Docker Desktop K8s**: General Kubernetes development on Mac/Windows
- **Minikube**: When you need specific K8s addons or VM isolation

---

## Next Steps

- Configure ingress for better routing
- Set up CI/CD pipeline for automated deployments
- Add horizontal pod autoscaling (HPA)
- Implement monitoring and alerting
- Set up backup strategy for MongoDB
- Review the AWS_DEPLOYMENT_GUIDE.md for cloud deployment

---

## Additional Resources

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kind Documentation](https://kind.sigs.k8s.io/)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
