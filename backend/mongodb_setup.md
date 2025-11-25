# MongoDB Setup Guide for CareFlowAI

This guide will help you set up MongoDB for the CareFlowAI backend.

## Option 1: Local MongoDB Installation (Recommended for Development)

### Windows

#### Step 1: Download MongoDB

1. Go to: **https://www.mongodb.com/try/download/community**
2. Select:
   - **Version:** 7.0.x (Current)
   - **Platform:** Windows
   - **Package:** MSI
3. Click **Download**

#### Step 2: Install MongoDB

1. **Run the downloaded `.msi` file**
2. Click **Next** on welcome screen
3. Accept the license agreement
4. Choose **Complete** installation type
5. **IMPORTANT:** Check "Install MongoDB as a Service"
   - This makes MongoDB start automatically
   - Service Name: `MongoDB`
6. **Optional:** Install MongoDB Compass (GUI tool)
   - Check the box if you want a visual tool
7. Click **Install**
8. Wait for installation to complete
9. Click **Finish**

#### Step 3: Verify Installation

Open Command Prompt or PowerShell and run:

```bash
mongod --version
```

You should see something like:
```
db version v7.0.x
```

#### Step 4: Check if MongoDB is Running

```bash
# Check if MongoDB service is running
sc query MongoDB

# Or use Task Manager:
# Press Ctrl+Shift+Esc → Services tab → Look for "MongoDB"
```

#### Step 5: Start MongoDB (if not running)

```bash
# Start MongoDB service
net start MongoDB
```

#### Step 6: Install MongoDB Shell (mongosh)

The MongoDB Shell (mongosh) is used to interact with MongoDB from the command line.

1. Go to: **https://www.mongodb.com/try/download/shell**
2. Select:
   - **Version:** Latest
   - **Platform:** Windows 64-bit (8.1+) (MSI)
3. Click **Download**
4. **Run the downloaded `.msi` file**
5. Click **Next** on welcome screen
6. Accept the license agreement
7. Choose installation location (default is fine)
8. Click **Install**
9. Click **Finish**

**Verify mongosh Installation:**

```bash
mongosh --version
```

You should see version information like:
```
2.x.x
```

#### Step 7: Test Connection

```bash
# Connect to MongoDB shell
mongosh mongodb://localhost:27017

# You should see: "Connected to MongoDB"
# Type 'exit' to quit
```

#### Default Connection
   - MongoDB runs on: `mongodb://localhost:27017`
   - This is already configured in your `.env` file

#### Windows-Specific Troubleshooting

**Issue: "mongod is not recognized"**

Solution: MongoDB is not in PATH
1. Add MongoDB to PATH:
   - Search "Environment Variables" in Windows
   - Edit "Path" variable
   - Add: `C:\Program Files\MongoDB\Server\7.0\bin`
2. Restart Command Prompt

**Issue: "Service won't start"**

Solution:
```bash
# Stop service
net stop MongoDB

# Start service
net start MongoDB
```

**Issue: "Access denied"**

Solution: Run Command Prompt as Administrator

#### Default Configuration

MongoDB runs with these defaults on Windows:
- **Host:** localhost
- **Port:** 27017
- **No authentication** (for local development)
- **Data directory:** `C:\Program Files\MongoDB\Server\7.0\data`
- **Log directory:** `C:\Program Files\MongoDB\Server\7.0\log`

### macOS

1. **Install using Homebrew**
   ```bash
   # Install Homebrew if not already installed
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

   # Install MongoDB
   brew tap mongodb/brew
   brew install mongodb-community
   ```

2. **Start MongoDB**
   ```bash
   brew services start mongodb-community
   ```

3. **Verify Installation**
   ```bash
   mongod --version
   ```

### Linux (Ubuntu/Debian)

1. **Import MongoDB GPG Key**
   ```bash
   curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor
   ```

2. **Add MongoDB Repository**
   ```bash
   echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] \
   https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/7.0 multiverse" | \
   sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
   ```

3. **Install MongoDB**
   ```bash
   sudo apt-get update
   sudo apt-get install -y mongodb-org
   ```

4. **Start MongoDB**
   ```bash
   sudo systemctl start mongod
   sudo systemctl enable mongod
   ```

---

## Option 2: MongoDB Atlas (Cloud - Free Tier Available)

If you don't want to install MongoDB locally, use MongoDB Atlas (cloud):

1. **Create Atlas Account**
   - Visit: https://www.mongodb.com/cloud/atlas/register
   - Sign up for free account

2. **Create a Free Cluster**
   - Choose Free Tier (M0)
   - Select a cloud provider and region
   - Click "Create Cluster"

3. **Configure Database Access**
   - Go to "Database Access" in sidebar
   - Click "Add New Database User"
   - Create username and password
   - Save credentials securely

4. **Configure Network Access**
   - Go to "Network Access" in sidebar
   - Click "Add IP Address"
   - Choose "Allow Access from Anywhere" (for development)
   - Or add your specific IP address

5. **Get Connection String**
   - Click "Connect" on your cluster
   - Choose "Connect your application"
   - Copy the connection string
   - Example: `mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/`

6. **Update `.env` File**
   ```bash
   MONGODB_URL=mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/
   DATABASE_NAME=careflowai
   ```

---

## Testing MongoDB Connection

### Using MongoDB Compass (GUI)

1. Open MongoDB Compass
2. Connect to: `mongodb://localhost:27017`
3. You should see the connection established

### Using MongoDB Shell

```bash
# Connect to MongoDB
mongosh

# Show databases
show dbs

# Use CareFlowAI database
use careflowai

# Show collections
show collections
```

---

## Verifying CareFlowAI Backend Connection

1. **Start the Backend**
   ```bash
   cd backend
   python run.py
   ```

2. **Check Console Output**
   You should see:
   ```
   Connected to MongoDB at mongodb://localhost:27017
   Using database: careflowai
   ```

3. **Test API**
   ```bash
   curl http://localhost:8000/health
   ```

   Expected response:
   ```json
   {
     "status": "healthy",
     "service": "CareFlowAI API",
     "database": "MongoDB"
   }
   ```

---

## Database Structure

CareFlowAI uses three collections:

1. **users** - User accounts (patients, doctors, receptionists)
2. **appointments** - Appointment records
3. **comments** - Comments on appointments

Collections are created automatically when you first use the API.

---

## Common Issues & Troubleshooting

### Issue: "Connection refused" Error

**Solution:**
- Ensure MongoDB is running:
  ```bash
  # Windows
  net start MongoDB

  # macOS
  brew services start mongodb-community

  # Linux
  sudo systemctl status mongod
  ```

### Issue: "Authentication failed"

**Solution:**
- Check MongoDB URL in `.env` file
- Verify username/password if using authentication
- For Atlas, ensure IP is whitelisted

### Issue: Port 27017 already in use

**Solution:**
- Check if MongoDB is already running
- Or change port in `.env`:
  ```
  MONGODB_URL=mongodb://localhost:27018
  ```

### Issue: "Database not found"

**Solution:**
- Databases are created automatically
- No action needed - just use the API

---

## MongoDB Management Tools

### MongoDB Compass (Recommended)
- GUI tool for MongoDB
- Download: https://www.mongodb.com/products/compass
- Features: Browse collections, run queries, view stats

### Studio 3T
- Advanced MongoDB GUI
- Download: https://studio3t.com/
- Free version available

### Robo 3T
- Lightweight MongoDB GUI
- Download: https://robomongo.org/

---

## Environment Variables

Update your `.env` file with MongoDB configuration:

```bash
# For Local MongoDB
MONGODB_URL=mongodb://localhost:27017
DATABASE_NAME=careflowai

# For MongoDB Atlas
MONGODB_URL=mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/
DATABASE_NAME=careflowai

# Other settings
SECRET_KEY=your-secret-key
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
UPLOAD_DIR=./uploads
MAX_UPLOAD_SIZE=10485760
```

---

## Next Steps

1. ✅ Install MongoDB (choose one option above)
2. ✅ Verify MongoDB is running
3. ✅ Update `.env` file if needed
4. ✅ Start backend server: `python run.py`
5. ✅ Test APIs using http://localhost:8000/docs

Your CareFlowAI backend is now connected to MongoDB! 🎉
