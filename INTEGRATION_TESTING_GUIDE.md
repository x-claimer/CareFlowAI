# CareFlowAI Integration Testing Guide

Complete guide for testing the integrated frontend and backend application.

---

## Prerequisites

Before testing, ensure you have:

1. **MongoDB installed and running**
   - See `backend/mongodb_setup.md` for installation instructions
   - MongoDB should be running on `mongodb://localhost:27017`

2. **Python 3.9+** installed
3. **Node.js 18+** installed
4. **Git** (for version control)

---

## Step 1: Setup Backend

### 1.1 Navigate to Backend Directory

```bash
cd backend
```

### 1.2 Create Python Virtual Environment

**Windows:**
```bash
python -m venv venv
venv\Scripts\activate
```

**macOS/Linux:**
```bash
python3 -m venv venv
source venv/bin/activate
```

### 1.3 Install Backend Dependencies

```bash
pip install -r requirements.txt
```

### 1.4 Verify .env File

Check that `backend/.env` exists with these settings:

```
MONGODB_URL=mongodb://localhost:27017
DATABASE_NAME=careflowai
SECRET_KEY=careflowai-secret-key-change-this-in-production-12345
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
UPLOAD_DIR=./uploads
MAX_UPLOAD_SIZE=10485760
```

### 1.5 Start MongoDB

**Windows:**
```bash
# Check if MongoDB is running
sc query MongoDB

# If not running, start it
net start MongoDB
```

**macOS:**
```bash
brew services start mongodb-community
```

**Linux:**
```bash
sudo systemctl start mongod
```

### 1.6 Verify MongoDB Connection

```bash
mongosh --eval "db.version()"
```

You should see the MongoDB version number.

### 1.7 Start Backend Server

```bash
python run.py
```

**Expected Output:**
```
Connected to MongoDB at mongodb://localhost:27017
Using database: careflowai
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     Started reloader process [xxxxx] using StatReload
INFO:     Started server process [xxxxx]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

### 1.8 Verify Backend is Running

Open a new terminal and test:

```bash
curl http://localhost:8000/health
```

**Expected Response:**
```json
{
  "status": "healthy",
  "service": "CareFlowAI API",
  "database": "MongoDB"
}
```

---

## Step 2: Setup Frontend

### 2.1 Navigate to Frontend Directory

Open a **NEW TERMINAL WINDOW** and navigate to frontend:

```bash
cd frontend
```

### 2.2 Install Frontend Dependencies

```bash
npm install
```

### 2.3 Verify .env File

Check that `frontend/.env` exists with:

```
VITE_API_URL=http://localhost:8000
```

### 2.4 Start Frontend Development Server

```bash
npm run dev
```

**Expected Output:**
```
VITE v7.2.4  ready in xxx ms

➜  Local:   http://localhost:5173/
➜  Network: use --host to expose
➜  press h + enter to show help
```

### 2.5 Open Application in Browser

Open your browser and navigate to:

```
http://localhost:5173
```

You should see the CareFlowAI login page.

---

## Step 3: Test Complete User Flows

### Test Scenario 1: Patient Journey

#### 3.1 Login as Patient

1. Open http://localhost:5173 in your browser
2. Fill in the login form:
   - **Email:** `patient@test.com`
   - **Password:** `password123`
   - **Role:** `Patient`
3. Click **Sign In**

**Expected Result:**
- You should be redirected to the Home page
- You should see a welcome message with your name
- Navigation bar should show "Patient" role

#### 3.2 View Dashboard

**Expected Result:**
- You should see the dashboard with appointment cards
- Initially, there may be no appointments (empty state)
- You should see AI Nurse and AI Tutor sections

#### 3.3 Use AI Tutor

1. Scroll to the **AI Tutor** section
2. In the search box, type: `hypertension`
3. Click **Search**

**Expected Result:**
- You should see a definition of hypertension
- Examples of usage should appear
- Related information should be displayed

Try these other medical terms:
- `diabetes`
- `cholesterol`
- `cardiovascular`

#### 3.4 Use AI Nurse Chat

1. Scroll to the **AI Nurse** section
2. In the chat input, type: `What are normal blood sugar levels?`
3. Click **Send** or press Enter

**Expected Result:**
- AI Nurse should respond with information about blood sugar levels
- The response should appear in the chat interface

#### 3.5 View Appointments

1. Click on **Schedule** in the navigation bar

**Expected Result:**
- You should see the appointments page
- You may see an empty state if no appointments exist
- As a patient, you should only be able to view appointments

#### 3.6 Logout

1. Click on your profile name in the navigation bar
2. Click **Logout**

**Expected Result:**
- You should be redirected to the login page
- Session should be cleared

---

### Test Scenario 2: Doctor Workflow

#### 3.7 Login as Doctor

1. Go to login page
2. Fill in the login form:
   - **Email:** `doctor@test.com`
   - **Password:** `password123`
   - **Role:** `Doctor`
3. Click **Sign In**

**Expected Result:**
- Login successful
- Dashboard loads with doctor privileges

#### 3.8 Create Appointment

1. Click on **Schedule** in navigation
2. Click **Create New Appointment** (or similar button)
3. Fill in appointment details:
   - **Patient Name:** `John Doe`
   - **Doctor Name:** `Dr. Smith`
   - **Date:** Select tomorrow's date
   - **Time:** `10:00 AM`
   - **Reason:** `Annual checkup`
4. Click **Create Appointment**

**Expected Result:**
- Appointment should be created successfully
- New appointment should appear in the list
- You should see a success message

#### 3.9 Update Appointment

1. Find the appointment you just created
2. Click **Edit** or similar action
3. Change the status to `Completed`
4. Click **Save**

**Expected Result:**
- Appointment status should update
- Changes should be reflected immediately

#### 3.10 Add Comment to Appointment

1. Click on an appointment to view details
2. Find the **Comments** section
3. Type a comment: `Patient is healthy. Recommend annual follow-up.`
4. Click **Add Comment**

**Expected Result:**
- Comment should be added
- Comment should appear with timestamp
- Your name should appear as the comment author

#### 3.11 Delete Appointment

1. Find an appointment
2. Click **Delete** or trash icon
3. Confirm deletion

**Expected Result:**
- Appointment should be deleted
- It should disappear from the list
- You should see a confirmation message

---

### Test Scenario 3: Receptionist Workflow

#### 3.12 Login as Receptionist

1. Logout from doctor account
2. Login with:
   - **Email:** `receptionist@test.com`
   - **Password:** `password123`
   - **Role:** `Receptionist`

**Expected Result:**
- Login successful
- Dashboard loads with receptionist privileges

#### 3.13 Manage Appointments

Receptionists should have the same appointment management capabilities as doctors:
- Create appointments
- Update appointments
- View all appointments
- Add comments

Test creating 2-3 appointments with different details.

---

### Test Scenario 4: AI Features

#### 3.14 Test Popular Medical Terms

1. Login as any user
2. Go to AI Tutor section
3. Click on any popular term suggestion

**Expected Result:**
- Term definition should load
- Information should be comprehensive

#### 3.15 Test AI Nurse with File Upload (if implemented)

1. Go to AI Nurse section
2. Look for file upload option
3. Upload a sample health report (PDF/Image)

**Expected Result:**
- File should upload successfully
- AI should analyze the report
- Summary should be displayed

---

## Step 4: Test API Directly (Optional)

### 4.1 Test Authentication Endpoint

```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "patient@test.com",
    "password": "password123",
    "role": "patient"
  }'
```

**Expected Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "user": {
    "id": "...",
    "email": "patient@test.com",
    "name": "patient",
    "role": "patient"
  }
}
```

### 4.2 Test with Interactive API Docs

1. Open http://localhost:8000/docs
2. Click on any endpoint
3. Click "Try it out"
4. Fill in parameters
5. Click "Execute"

---

## Step 5: Verify Database

### 5.1 Connect to MongoDB

```bash
mongosh mongodb://localhost:27017
```

### 5.2 Check Database and Collections

```javascript
// Switch to careflowai database
use careflowai

// Show all collections
show collections

// Expected output:
// users
// appointments
// comments

// Count documents in each collection
db.users.countDocuments()
db.appointments.countDocuments()
db.comments.countDocuments()
```

### 5.3 View Sample Data

```javascript
// View users
db.users.find().pretty()

// View appointments
db.appointments.find().pretty()

// View comments
db.comments.find().pretty()
```

### 5.4 Exit MongoDB Shell

```javascript
exit
```

---

## Common Testing Scenarios Checklist

### Authentication & Authorization
- [ ] Login as Patient
- [ ] Login as Doctor
- [ ] Login as Receptionist
- [ ] Logout functionality
- [ ] Protected routes redirect to login
- [ ] Token persistence (refresh page stays logged in)
- [ ] Token expiration handling

### Appointments (Doctor/Receptionist)
- [ ] Create new appointment
- [ ] View all appointments
- [ ] Filter appointments by status
- [ ] Update appointment details
- [ ] Update appointment status
- [ ] Delete appointment
- [ ] Add comment to appointment
- [ ] View appointment comments

### Appointments (Patient)
- [ ] View own appointments
- [ ] Cannot create appointments
- [ ] Cannot delete appointments
- [ ] Can view appointment details

### AI Tutor
- [ ] Search medical terms
- [ ] View popular terms
- [ ] Click on popular term suggestions
- [ ] View term definitions
- [ ] View examples

### AI Nurse
- [ ] Send chat message
- [ ] Receive AI response
- [ ] Upload health report (if implemented)
- [ ] View report analysis

### UI/UX
- [ ] Responsive design (mobile, tablet, desktop)
- [ ] Loading states appear during API calls
- [ ] Error messages display correctly
- [ ] Success messages display correctly
- [ ] Navigation works correctly
- [ ] Logout clears session

---

## Troubleshooting

### Issue 1: Backend Not Starting

**Error:** `Connection refused` or `MongoDB not found`

**Solution:**
1. Verify MongoDB is running: `sc query MongoDB` (Windows) or `brew services list` (macOS)
2. Start MongoDB if not running
3. Check MongoDB URL in `backend/.env`

### Issue 2: Frontend Can't Connect to Backend

**Error:** `Failed to fetch` or `Network error`

**Solution:**
1. Verify backend is running on http://localhost:8000
2. Check `frontend/.env` has correct `VITE_API_URL`
3. Check CORS settings in `backend/app/main.py`
4. Restart both frontend and backend servers

### Issue 3: Login Fails

**Error:** `401 Unauthorized` or `Login failed`

**Solution:**
1. Check backend logs for errors
2. Verify MongoDB is connected
3. Try with test credentials: `patient@test.com` / `password123`
4. Check browser console for detailed errors

### Issue 4: Appointments Not Loading

**Error:** `403 Forbidden` or empty list

**Solution:**
1. Verify you're logged in as the correct role
2. Check if appointments exist in database
3. Open browser DevTools Network tab to see API calls
4. Check backend logs for errors

### Issue 5: MongoDB Connection Issues

**Error:** `MongoServerError` or connection timeout

**Solution:**
```bash
# Check if MongoDB is running
mongosh --eval "db.version()"

# If not running, start it
# Windows:
net start MongoDB

# macOS:
brew services start mongodb-community

# Linux:
sudo systemctl start mongod
```

### Issue 6: Port Already in Use

**Error:** `Port 8000 already in use` or `Port 5173 already in use`

**Solution:**
```bash
# Find and kill process using port
# Windows:
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# macOS/Linux:
lsof -ti:8000 | xargs kill -9
```

---

## Performance Testing

### Test Response Times

Use browser DevTools Network tab to check:
- Login: Should be < 500ms
- Get Appointments: Should be < 300ms
- AI Tutor Search: Should be < 2s
- AI Nurse Chat: Should be < 3s

### Test with Multiple Users

1. Open multiple browser windows/tabs
2. Login as different users
3. Perform actions simultaneously
4. Verify data consistency

---

## Security Testing

### Test Protected Routes

1. Logout from application
2. Try to access http://localhost:5173/ directly

**Expected:** Should redirect to login page

### Test Token Expiration

1. Login and wait for 30 minutes (token expiration time)
2. Try to perform an action

**Expected:** Should get 401 error and redirect to login

### Test Role-Based Access

1. Login as Patient
2. Try to create appointment via API directly

**Expected:** Should get 403 Forbidden error

---

## Next Steps After Testing

Once all tests pass:

1. ✅ Document any bugs found
2. ✅ Create test user accounts with sample data
3. ✅ Prepare for deployment
4. ✅ Consider adding automated tests
5. ✅ Review and improve error handling
6. ✅ Optimize performance bottlenecks

---

## Quick Start Commands Summary

**Terminal 1 - Backend:**
```bash
cd backend
venv\Scripts\activate    # Windows
# OR
source venv/bin/activate # macOS/Linux
python run.py
```

**Terminal 2 - Frontend:**
```bash
cd frontend
npm run dev
```

**Terminal 3 - MongoDB:**
```bash
# Windows
net start MongoDB

# macOS
brew services start mongodb-community

# Linux
sudo systemctl start mongod
```

**Open Browser:**
```
http://localhost:5173
```

---

## Test Credentials

Use these credentials for testing:

**Patient:**
- Email: `patient@test.com`
- Password: `password123`
- Role: `patient`

**Doctor:**
- Email: `doctor@test.com`
- Password: `password123`
- Role: `doctor`

**Receptionist:**
- Email: `receptionist@test.com`
- Password: `password123`
- Role: `receptionist`

---

## Success Criteria

The integration is successful when:

✅ Backend starts without errors
✅ Frontend connects to backend
✅ MongoDB stores data correctly
✅ Login works for all roles
✅ Appointments can be created, updated, deleted
✅ AI Tutor returns medical definitions
✅ AI Nurse responds to questions
✅ Role-based access control works
✅ No console errors in browser
✅ All API calls return expected responses

Congratulations! Your CareFlowAI application is fully integrated and working! 🎉
