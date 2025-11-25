# CareFlowAI - Quick Start Guide

Get your CareFlowAI application up and running in 5 minutes!

---

## Prerequisites

- MongoDB installed and running
- Python 3.9+
- Node.js 18+

---

## Step 1: Start MongoDB

**Windows:**
```bash
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

**Verify MongoDB is running:**
```bash
mongosh --eval "db.version()"
```

---

## Step 2: Start Backend

Open a terminal window:

```bash
# Navigate to backend
cd backend

# Activate virtual environment
# Windows:
venv\Scripts\activate

# macOS/Linux:
source venv/bin/activate

# Install dependencies (first time only)
pip install -r requirements.txt

# Start server
python run.py
```

**Expected Output:**
```
Connected to MongoDB at mongodb://localhost:27017
INFO:     Uvicorn running on http://0.0.0.0:8000
```

Leave this terminal running.

---

## Step 3: Start Frontend

Open a **NEW** terminal window:

```bash
# Navigate to frontend
cd frontend

# Install dependencies (first time only)
npm install

# Start development server
npm run dev
```

**Expected Output:**
```
VITE v7.2.4  ready in xxx ms
➜  Local:   http://localhost:5173/
```

Leave this terminal running.

---

## Step 4: Open Application

Open your browser and go to:

```
http://localhost:5173
```

---

## Step 5: Test Login

Use these test credentials:

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

## Quick Test Checklist

1. ✅ Login works
2. ✅ Dashboard loads
3. ✅ AI Tutor search works (try searching "diabetes")
4. ✅ AI Nurse chat works (try asking a health question)
5. ✅ Appointments page loads
6. ✅ Create appointment works (as doctor/receptionist)
7. ✅ Logout works

---

## Troubleshooting

### Backend won't start?
- Make sure MongoDB is running
- Check if port 8000 is available
- Verify `.env` file exists in `backend/` folder

### Frontend won't start?
- Make sure you ran `npm install`
- Check if port 5173 is available
- Verify `.env` file exists in `frontend/` folder

### Can't login?
- Check browser console for errors
- Verify backend is running on http://localhost:8000
- Try: http://localhost:8000/docs to see if API is accessible

### MongoDB connection issues?
```bash
# Check MongoDB status
sc query MongoDB          # Windows
brew services list        # macOS
sudo systemctl status mongod  # Linux
```

---

## What's Next?

For detailed testing instructions, see:
- `INTEGRATION_TESTING_GUIDE.md` - Complete testing scenarios
- `backend/API_TESTING.md` - API endpoint testing
- `backend/mongodb_setup.md` - MongoDB setup guide

---

## Stopping the Application

**Stop Frontend:**
Press `Ctrl + C` in the frontend terminal

**Stop Backend:**
Press `Ctrl + C` in the backend terminal

**Stop MongoDB (optional):**
```bash
# Windows
net stop MongoDB

# macOS
brew services stop mongodb-community

# Linux
sudo systemctl stop mongod
```

---

## Architecture Overview

```
┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│                 │         │                 │         │                 │
│    Frontend     │────────▶│     Backend     │────────▶│    MongoDB      │
│  (React + Vite) │  HTTP   │  (FastAPI)      │         │   (Database)    │
│  Port: 5173     │         │  Port: 8000     │         │  Port: 27017    │
│                 │         │                 │         │                 │
└─────────────────┘         └─────────────────┘         └─────────────────┘
```

---

## File Structure

```
CareFlowAI/
├── backend/              # FastAPI Backend
│   ├── app/
│   │   ├── routes/      # API endpoints
│   │   ├── schemas/     # Data models
│   │   └── services/    # Business logic
│   ├── .env             # Environment variables
│   ├── run.py           # Server entry point
│   └── requirements.txt # Python dependencies
│
├── frontend/            # React Frontend
│   ├── src/
│   │   ├── components/  # UI components
│   │   ├── contexts/    # React contexts
│   │   ├── lib/         # API client
│   │   └── pages/       # Page components
│   ├── .env             # Environment variables
│   └── package.json     # Node dependencies
│
└── INTEGRATION_TESTING_GUIDE.md  # Full testing guide
```

---

Happy coding! 🚀
