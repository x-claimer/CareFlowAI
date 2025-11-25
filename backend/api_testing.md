# CareFlowAI API Testing Guide

Complete guide to testing all CareFlowAI API endpoints using multiple methods.

---

## Prerequisites

1. **MongoDB Running**
   ```bash
   # Check if MongoDB is running
   mongosh --eval "db.version()"

   # Or start MongoDB service on Windows
   net start MongoDB
   ```

2. **Backend Server Running**
   ```bash
   cd backend
   python run.py
   ```

   You should see:
   ```
   Connected to MongoDB at mongodb://localhost:27017
   INFO:     Uvicorn running on http://0.0.0.0:8000
   ```

---

## Method 1: Interactive API Docs (Swagger UI) - EASIEST!

This is the **fastest and easiest** way to test APIs.

### Step 1: Open Swagger UI

Open your browser and go to: **http://localhost:8000/docs**

You'll see an interactive API documentation page!

### Step 2: Test Authentication

1. **Find the "Authentication" section**
2. **Click on "POST /api/auth/login"**
3. **Click "Try it out"**
4. **Enter the request body:**
   ```json
   {
     "email": "patient@test.com",
     "password": "password123",
     "role": "patient"
   }
   ```
5. **Click "Execute"**
6. **Copy the `access_token` from the response**

### Step 3: Authorize for Protected Endpoints

1. **Scroll to the top of the page**
2. **Click the "Authorize" button (green lock icon)**
3. **Paste your token** (without "Bearer")
4. **Click "Authorize"**
5. **Click "Close"**

Now you can test all protected endpoints!

### Step 4: Test Other Endpoints

Try these endpoints in order:

#### Get Current User
- Endpoint: `GET /api/auth/me`
- Click "Try it out" → "Execute"

#### Get Appointments
- Endpoint: `GET /api/appointments`
- Click "Try it out" → "Execute"

#### Create Appointment (login as doctor first!)
- Login again with role "doctor"
- Endpoint: `POST /api/appointments`
- Request body:
  ```json
  {
    "patient_name": "John Doe",
    "doctor_name": "Dr. Smith",
    "date": "2024-12-25",
    "time": "10:00 AM",
    "reason": "Annual checkup"
  }
  ```

#### AI Tutor Search
- Endpoint: `POST /api/ai/tutor/search`
- Request body:
  ```json
  {
    "query": "hypertension"
  }
  ```

---

## Method 2: Using cURL (Command Line)

### Authentication Endpoints

#### 1. Login

**Endpoint:** `POST /api/auth/login`

```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "patient@test.com",
    "password": "password123",
    "role": "patient"
  }'
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "user": {
    "id": "123",
    "email": "patient@test.com",
    "name": "patient",
    "role": "patient"
  }
}
```

**Save the access_token from response!**

#### 2. Get Current User

**Endpoint:** `GET /api/auth/me`

```bash
curl -X GET http://localhost:8000/api/auth/me \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

#### 3. Logout

**Endpoint:** `POST /api/auth/logout`

```bash
curl -X POST http://localhost:8000/api/auth/logout \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

### Appointment Endpoints

#### 1. Get All Appointments

**Endpoint:** `GET /api/appointments`

```bash
# Get all appointments
curl -X GET http://localhost:8000/api/appointments \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"

# Filter by status
curl -X GET "http://localhost:8000/api/appointments?status=scheduled" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

#### 2. Create Appointment (Doctor/Receptionist only)

**Endpoint:** `POST /api/appointments`

```bash
# First login as doctor or receptionist
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "doctor@test.com",
    "password": "password123",
    "role": "doctor"
  }'

# Create appointment
curl -X POST http://localhost:8000/api/appointments \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "patient_name": "John Doe",
    "doctor_name": "Dr. Smith",
    "date": "2024-12-25",
    "time": "10:00 AM",
    "reason": "Annual checkup"
  }'
```

#### 3. Update Appointment (Doctor/Receptionist only)

**Endpoint:** `PUT /api/appointments/{appointment_id}`

```bash
curl -X PUT http://localhost:8000/api/appointments/APPOINTMENT_ID \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "completed",
    "reason": "Annual checkup - completed successfully"
  }'
```

#### 4. Delete Appointment (Doctor/Receptionist only)

**Endpoint:** `DELETE /api/appointments/{appointment_id}`

```bash
curl -X DELETE http://localhost:8000/api/appointments/APPOINTMENT_ID \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

#### 5. Add Comment to Appointment

**Endpoint:** `POST /api/appointments/{appointment_id}/comments`

```bash
curl -X POST http://localhost:8000/api/appointments/APPOINTMENT_ID/comments \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Patient has been regular with checkups. Review previous reports."
  }'
```

---

### AI Nurse Endpoints

#### 1. Analyze Health Report

**Endpoint:** `POST /api/ai/nurse/analyze-report`

```bash
curl -X POST http://localhost:8000/api/ai/nurse/analyze-report \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -F "file=@/path/to/health-report.pdf"
```

**Supported file types:** PDF, JPG, PNG (max 10MB)

**Response:**
```json
{
  "analysis": "I've analyzed your health report...",
  "summary": "Health report shows generally good indicators...",
  "file_name": "health-report.pdf"
}
```

#### 2. Chat with AI Nurse

**Endpoint:** `POST /api/ai/nurse/chat`

```bash
curl -X POST http://localhost:8000/api/ai/nurse/chat \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "question": "What do my cholesterol levels mean?",
    "report_id": "optional-report-id"
  }'
```

**Response:**
```json
{
  "answer": "I understand your question...",
  "message_id": "unique-message-id"
}
```

---

### AI Tutor Endpoints

#### 1. Search Medical Term

**Endpoint:** `POST /api/ai/tutor/search`

```bash
curl -X POST http://localhost:8000/api/ai/tutor/search \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "hypertension"
  }'
```

**Response:**
```json
{
  "term": "hypertension",
  "definition": "Hypertension, also known as high blood pressure...",
  "examples": [
    "Common usage: 'The patient was diagnosed with hypertension'",
    "Related terms: cardiovascular disease...",
    "When to seek help: If you experience persistent headaches..."
  ]
}
```

#### 2. Get Popular Terms

**Endpoint:** `GET /api/ai/tutor/popular-terms`

```bash
curl -X GET http://localhost:8000/api/ai/tutor/popular-terms \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Response:**
```json
{
  "terms": [
    "Hypertension",
    "Diabetes",
    "Cholesterol",
    "BMI",
    "Cardiovascular",
    "Inflammation"
  ]
}
```

---

### Complete Test Flow with cURL

```bash
# 1. Login
TOKEN=$(curl -s -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"doctor@test.com","password":"password123","role":"doctor"}' \
  | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

echo "Token: $TOKEN"

# 2. Create appointment
curl -X POST http://localhost:8000/api/appointments \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "patient_name": "Jane Doe",
    "doctor_name": "Dr. Smith",
    "date": "2024-12-30",
    "time": "2:00 PM",
    "reason": "Follow-up"
  }'

# 3. Get all appointments
curl -X GET http://localhost:8000/api/appointments \
  -H "Authorization: Bearer $TOKEN"

# 4. AI Tutor
curl -X POST http://localhost:8000/api/ai/tutor/search \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query": "cholesterol"}'
```

---

## Method 3: Using Python Requests

Create a file `test_api.py`:

```python
import requests
import json

BASE_URL = "http://localhost:8000"

# 1. Login
def login(email, password, role):
    response = requests.post(
        f"{BASE_URL}/api/auth/login",
        json={
            "email": email,
            "password": password,
            "role": role
        }
    )
    data = response.json()
    print(f"✅ Logged in as: {data['user']['name']} ({data['user']['role']})")
    return data['access_token']

# 2. Get appointments
def get_appointments(token):
    response = requests.get(
        f"{BASE_URL}/api/appointments",
        headers={"Authorization": f"Bearer {token}"}
    )
    appointments = response.json()
    print(f"✅ Found {len(appointments)} appointments")
    return appointments

# 3. Create appointment
def create_appointment(token, data):
    response = requests.post(
        f"{BASE_URL}/api/appointments",
        headers={"Authorization": f"Bearer {token}"},
        json=data
    )
    appointment = response.json()
    print(f"✅ Created appointment: {appointment['id']}")
    return appointment

# 4. AI Tutor search
def search_term(token, query):
    response = requests.post(
        f"{BASE_URL}/api/ai/tutor/search",
        headers={"Authorization": f"Bearer {token}"},
        json={"query": query}
    )
    result = response.json()
    print(f"✅ Found definition for: {result['term']}")
    print(f"   {result['definition'][:100]}...")
    return result

# Run tests
if __name__ == "__main__":
    print("🧪 Testing CareFlowAI APIs\n")

    # Login as doctor
    token = login("doctor@test.com", "password123", "doctor")

    # Get appointments
    appointments = get_appointments(token)

    # Create appointment
    new_apt = create_appointment(token, {
        "patient_name": "Test Patient",
        "doctor_name": "Dr. Test",
        "date": "2024-12-31",
        "time": "3:00 PM",
        "reason": "Checkup"
    })

    # Search medical term
    result = search_term(token, "hypertension")

    print("\n✅ All tests passed!")
```

Run it:
```bash
python test_api.py
```

---

## Method 4: Using Postman

### Step 1: Install Postman
Download from: https://www.postman.com/downloads/

### Step 2: Import Collection

Create a new collection called "CareFlowAI"

### Step 3: Setup Environment Variables

1. Click "Environments" → "Create Environment"
2. Name: "CareFlowAI Local"
3. Add variables:
   - `base_url`: `http://localhost:8000`
   - `token`: (leave empty, will be set automatically)

### Step 4: Create Requests

#### Request 1: Login
- Method: POST
- URL: `{{base_url}}/api/auth/login`
- Body (JSON):
  ```json
  {
    "email": "doctor@test.com",
    "password": "password123",
    "role": "doctor"
  }
  ```
- Tests (to save token):
  ```javascript
  pm.environment.set("token", pm.response.json().access_token);
  ```

#### Request 2: Get Appointments
- Method: GET
- URL: `{{base_url}}/api/appointments`
- Auth: Bearer Token
- Token: `{{token}}`

#### Request 3: Create Appointment
- Method: POST
- URL: `{{base_url}}/api/appointments`
- Auth: Bearer Token
- Token: `{{token}}`
- Body (JSON):
  ```json
  {
    "patient_name": "John Doe",
    "doctor_name": "Dr. Smith",
    "date": "2024-12-25",
    "time": "10:00 AM",
    "reason": "Annual checkup"
  }
  ```

---

## Complete Test Scenarios

### Scenario 1: Patient Journey

```bash
# 1. Patient logs in
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"patient@test.com","password":"password123","role":"patient"}'

# 2. View appointments
curl -X GET http://localhost:8000/api/appointments \
  -H "Authorization: Bearer TOKEN"

# 3. Upload health report (requires file)
curl -X POST http://localhost:8000/api/ai/nurse/analyze-report \
  -H "Authorization: Bearer TOKEN" \
  -F "file=@/path/to/report.pdf"

# 4. Chat with AI Nurse
curl -X POST http://localhost:8000/api/ai/nurse/chat \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"question":"What do my cholesterol levels mean?"}'

# 5. Search medical term
curl -X POST http://localhost:8000/api/ai/tutor/search \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query":"diabetes"}'
```

### Scenario 2: Doctor Workflow

```bash
# 1. Doctor logs in
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"doctor@test.com","password":"password123","role":"doctor"}'

# 2. Create appointment
curl -X POST http://localhost:8000/api/appointments \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "patient_name": "Alice Johnson",
    "doctor_name": "Dr. Smith",
    "date": "2024-12-26",
    "time": "11:00 AM",
    "reason": "Annual physical"
  }'

# 3. Add comment to appointment
curl -X POST http://localhost:8000/api/appointments/APPOINTMENT_ID/comments \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"content":"Patient history reviewed. Recommend blood work."}'

# 4. Update appointment status
curl -X PUT http://localhost:8000/api/appointments/APPOINTMENT_ID \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"status":"completed"}'
```

---

## Testing Different User Roles

### Patient
```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "patient@test.com",
    "password": "password123",
    "role": "patient"
  }'
```

### Doctor
```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "doctor@test.com",
    "password": "password123",
    "role": "doctor"
  }'
```

### Receptionist
```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "receptionist@test.com",
    "password": "password123",
    "role": "receptionist"
  }'
```

---

## Testing Checklist

### Authentication APIs
- [ ] POST /api/auth/login (patient)
- [ ] POST /api/auth/login (doctor)
- [ ] POST /api/auth/login (receptionist)
- [ ] GET /api/auth/me
- [ ] POST /api/auth/logout

### Appointment APIs
- [ ] GET /api/appointments (all)
- [ ] GET /api/appointments?status=scheduled
- [ ] POST /api/appointments (create)
- [ ] PUT /api/appointments/{id} (update)
- [ ] DELETE /api/appointments/{id}
- [ ] POST /api/appointments/{id}/comments

### AI Nurse APIs
- [ ] POST /api/ai/nurse/analyze-report (with PDF file)
- [ ] POST /api/ai/nurse/chat

### AI Tutor APIs
- [ ] POST /api/ai/tutor/search
- [ ] GET /api/ai/tutor/popular-terms

---

## Common Test Data

### Test Users
```json
{
  "email": "patient@test.com",
  "password": "password123",
  "role": "patient"
}

{
  "email": "doctor@test.com",
  "password": "password123",
  "role": "doctor"
}

{
  "email": "receptionist@test.com",
  "password": "password123",
  "role": "receptionist"
}
```

### Test Appointment
```json
{
  "patient_name": "John Doe",
  "doctor_name": "Dr. Smith",
  "date": "2024-12-25",
  "time": "10:00 AM",
  "reason": "Annual checkup"
}
```

### Medical Terms to Search
- hypertension
- diabetes
- cholesterol
- cardiovascular
- inflammation

---

## Troubleshooting

### Issue: 401 Unauthorized

**Cause:** Token expired or invalid

**Solution:**
- Check if your access token is valid and not expired
- Ensure the `Authorization` header is properly formatted: `Bearer YOUR_TOKEN`
- Re-login to get new token

### Issue: 403 Forbidden

**Cause:** Insufficient permissions

**Solution:**
- Verify your user role has permission for the endpoint
- Check role requirements in the endpoint documentation
- Patient users cannot create/update/delete appointments
- Login with doctor/receptionist role for appointment management

### Issue: 422 Unprocessable Entity

**Cause:** Invalid request body

**Solution:**
- Verify request body matches the expected schema
- Check required fields are provided
- Validate data types and formats
- Check JSON format is correct

### Issue: Connection refused

**Cause:** Backend not running

**Solution:**
- Start backend: `python run.py`
- Check MongoDB is running: `mongosh --eval "db.version()"`
- Verify port 8000 is not in use

---

## Quick Reference

### Get Token (Bash)
```bash
TOKEN=$(curl -s -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"doctor@test.com","password":"password123","role":"doctor"}' \
  | python -c "import sys, json; print(json.load(sys.stdin)['access_token'])")
```

### Test with Token
```bash
curl -H "Authorization: Bearer $TOKEN" http://localhost:8000/api/appointments
```

---

## Notes

- **Auto-Create Users**: The login endpoint automatically creates users if they don't exist (demo mode)
- **Token Expiration**: Access tokens expire after 30 minutes (configurable in `.env`)
- **Role-Based Access**: Some endpoints require specific roles (doctor/receptionist for appointment management)
- **File Upload**: Health report analysis accepts files up to 10MB
- **Interactive Docs**: Visit `http://localhost:8000/docs` for interactive API documentation

---

## Next Steps

1. ✅ Start MongoDB
2. ✅ Start backend server
3. ✅ Open http://localhost:8000/docs
4. ✅ Test login endpoint
5. ✅ Authorize with token
6. ✅ Test other endpoints

**Recommended:** Start with the Swagger UI (Method 1) - it's the easiest!
