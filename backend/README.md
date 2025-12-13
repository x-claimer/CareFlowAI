# CareFlowAI Backend

AI-Powered Healthcare Management System Backend built with FastAPI, providing robust APIs for appointment management, AI-powered health analysis, and medical education.

---

## 🚀 Tech Stack

- **FastAPI** - High-performance Python web framework
- **SQLAlchemy 2.0** - Modern async ORM
- **SQLite** - Lightweight, serverless database
- **JWT (python-jose)** - Secure authentication
- **Bcrypt (passlib)** - Password hashing
- **Pydantic v2** - Data validation with type hints
- **Uvicorn** - ASGI server with async support
- **Python 3.11+** - Modern Python features

---

## ✨ Features

### Core Functionality
- **JWT Authentication** - Secure token-based authentication
- **Role-Based Access Control** - Patient, Doctor, Receptionist permissions
- **Appointment Management** - CRUD operations with status tracking
- **Comments System** - Collaborative notes on appointments
- **File Upload** - Health report storage and management

### AI Services
- **AI Nurse** - Health report analysis and interactive chat
- **AI Tutor** - Medical terminology search and education
- **Modular AI Layer** - Ready for integration with OpenAI, Google Gemini, or custom models

### Security
- **Encrypted Passwords** - Bcrypt hashing
- **Token Expiration** - Automatic session management
- **CORS Configuration** - Secure cross-origin requests
- **Input Validation** - Pydantic schemas for all endpoints

---

## 📁 Project Structure

```
backend/
├── app/
│   ├── models/                  # Database models (SQLAlchemy)
│   │   ├── user.py             # User model
│   │   ├── appointment.py      # Appointment model
│   │   └── comment.py          # Comment model
│   ├── schemas/                 # Pydantic schemas
│   │   ├── user.py             # User schemas
│   │   ├── appointment.py      # Appointment schemas
│   │   ├── comment.py          # Comment schemas
│   │   └── auth.py             # Auth schemas
│   ├── routes/                  # API route handlers
│   │   ├── auth.py             # Authentication endpoints
│   │   ├── appointments.py     # Appointment endpoints
│   │   ├── ai_nurse.py         # AI Nurse endpoints
│   │   └── ai_tutor.py         # AI Tutor endpoints
│   ├── services/                # Business logic
│   │   ├── auth_service.py     # Authentication service
│   │   ├── appointment_service.py  # Appointment service
│   │   ├── ai_nurse_service.py # AI Nurse service
│   │   └── ai_tutor_service.py # AI Tutor service
│   ├── utils/                   # Utility functions
│   │   ├── security.py         # Password hashing, JWT
│   │   └── dependencies.py     # FastAPI dependencies
│   ├── database.py              # Database configuration
│   └── main.py                  # FastAPI application
├── scripts/                     # Utility scripts
│   ├── init_db.py              # Initialize database
│   ├── seed_appointments.py    # Seed sample data
│   └── add_admin.py            # Create admin user
├── uploads/                     # Uploaded health reports
├── requirements.txt             # Python dependencies
├── run.py                       # Application entry point
├── .env.example                 # Environment variables template
└── README.md                    # This file
```

---

## 🛠️ Getting Started

### Prerequisites
- **Python 3.11+** - [Download Python](https://www.python.org/downloads/)
- **pip** - Comes with Python
- **Virtual Environment** (recommended)

### Installation

```bash
# Navigate to the backend directory
cd backend

# Create virtual environment (Windows)
python -m venv venv
venv\Scripts\activate

# Create virtual environment (macOS/Linux)
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Configure environment variables
cp .env.example .env
# Edit .env with your configuration
```

### Environment Configuration

Create a `.env` file in the backend directory:

```env
# Database
DATABASE_URL=sqlite:///./careflowai.db

# Security
SECRET_KEY=your-secret-key-here-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# AI Services (optional)
OPENAI_API_KEY=your-openai-key
GOOGLE_API_KEY=your-google-key

# CORS
FRONTEND_URL=http://localhost:5173
```

### Database Setup

```bash
# Initialize database and create tables
python scripts/init_db.py

# (Optional) Seed sample appointments
python scripts/seed_appointments.py

# (Optional) Create admin user
python scripts/add_admin.py
```

### Run the Application

```bash
# Using the run script
python run.py

# Or with uvicorn directly
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at: **http://localhost:8000**

### API Documentation

Interactive API documentation is available at:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

---

## 📚 API Endpoints

### Authentication (`/api/auth`)

| Method | Endpoint | Description | Access |
|--------|----------|-------------|--------|
| POST | `/login` | Login and get JWT token | Public |
| POST | `/logout` | Logout and invalidate token | Authenticated |
| GET | `/me` | Get current user info | Authenticated |

**Example Login Request:**
```json
{
  "email": "patient@example.com",
  "password": "password123",
  "role": "patient"
}
```

**Example Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer",
  "user": {
    "id": 1,
    "email": "patient@example.com",
    "full_name": "John Doe",
    "role": "patient"
  }
}
```

### Appointments (`/api/appointments`)

| Method | Endpoint | Description | Access |
|--------|----------|-------------|--------|
| GET | `/` | Get all appointments | Patient: own only, Doctor/Receptionist: all |
| POST | `/` | Create appointment | Doctor, Receptionist |
| PUT | `/{id}` | Update appointment | Doctor, Receptionist |
| DELETE | `/{id}` | Delete appointment | Doctor, Receptionist |
| POST | `/{id}/comments` | Add comment | Authenticated |

**Example Create Appointment:**
```json
{
  "patient_id": 1,
  "doctor_id": 2,
  "appointment_date": "2025-12-15T10:00:00",
  "reason": "Annual checkup",
  "status": "scheduled"
}
```

### AI Nurse (`/api/ai/nurse`)

| Method | Endpoint | Description | Access |
|--------|----------|-------------|--------|
| POST | `/analyze-report` | Upload and analyze health report | Authenticated |
| POST | `/chat` | Chat with AI Nurse | Authenticated |

**Example Analyze Report:**
```bash
curl -X POST "http://localhost:8000/api/ai/nurse/analyze-report" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@health_report.pdf"
```

### AI Tutor (`/api/ai/tutor`)

| Method | Endpoint | Description | Access |
|--------|----------|-------------|--------|
| POST | `/search` | Search medical terms | Public |
| GET | `/popular-terms` | Get popular medical terms | Public |

**Example Search:**
```json
{
  "term": "hypertension"
}
```

---

## 👥 User Roles & Permissions

### Patient
- ✅ View own appointments
- ✅ Upload health reports
- ✅ Chat with AI Nurse
- ✅ Use AI Tutor
- ✅ Add comments to own appointments
- ❌ Create/update/delete appointments

### Doctor
- ✅ All patient permissions
- ✅ Create appointments
- ✅ Update appointments
- ✅ Delete appointments
- ✅ View all appointments
- ✅ Add comments to any appointment

### Receptionist
- ✅ Create appointments
- ✅ Update appointments
- ✅ Delete appointments
- ✅ View all appointments
- ✅ Add administrative comments
- ❌ AI features (optional)

---

## 🗄️ Database Schema

### Users Table
```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email VARCHAR UNIQUE NOT NULL,
    password_hash VARCHAR NOT NULL,
    full_name VARCHAR NOT NULL,
    role VARCHAR NOT NULL,  -- patient, doctor, receptionist
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### Appointments Table
```sql
CREATE TABLE appointments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    patient_id INTEGER NOT NULL,
    doctor_id INTEGER NOT NULL,
    appointment_date DATETIME NOT NULL,
    reason TEXT,
    status VARCHAR DEFAULT 'scheduled',  -- scheduled, completed, cancelled
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES users(id),
    FOREIGN KEY (doctor_id) REFERENCES users(id)
);
```

### Comments Table
```sql
CREATE TABLE comments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    appointment_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    content TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (appointment_id) REFERENCES appointments(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

---

## 📤 File Upload

### Supported Formats
- **PDF** (.pdf)
- **Images** (.jpg, .jpeg, .png)
- **Max Size**: 10MB

### Storage
- Files saved to `uploads/` directory
- Filename format: `{timestamp}_{original_filename}`
- Automatic directory creation
- Secure file validation

---

## 🔒 Security Features

### Password Security
- Bcrypt hashing with salt rounds
- Never store plain text passwords
- Password validation on registration

### JWT Authentication
- HS256 algorithm
- Configurable expiration time
- Token refresh capability
- Secure secret key

### Input Validation
- Pydantic schemas for all inputs
- Type checking and conversion
- Custom validators for business logic
- Error messages for validation failures

### CORS Configuration
```python
CORS_ORIGINS = [
    "http://localhost:5173",  # Frontend dev
    "http://localhost:3000",  # Alternative frontend
    # Add production origins
]
```

---

## 🧪 Testing

### Run Tests
```bash
# Install test dependencies
pip install pytest pytest-asyncio httpx

# Run all tests
pytest

# Run with coverage
pytest --cov=app tests/

# Run specific test file
pytest tests/test_auth.py
```

### Test Structure
```
tests/
├── conftest.py              # Test configuration
├── test_auth.py            # Authentication tests
├── test_appointments.py    # Appointment tests
├── test_ai_nurse.py        # AI Nurse tests
└── test_ai_tutor.py        # AI Tutor tests
```

---

## 🚀 Deployment

### Production Setup

1. **Update Environment Variables**
```env
DATABASE_URL=postgresql://user:pass@host:5432/dbname
SECRET_KEY=use-a-strong-random-key-here
FRONTEND_URL=https://your-domain.com
```

2. **Use Production Database**
```bash
# PostgreSQL (recommended for production)
pip install psycopg2-binary
```

3. **Run with Production Server**
```bash
gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

### AWS Deployment
See the [AWS deployment guide](../aws/README.md) for complete instructions on deploying to AWS with auto-scaling, load balancing, and monitoring.

### Docker Deployment
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

## 🔧 Development

### Code Style
```bash
# Format code with black
black app/

# Sort imports
isort app/

# Lint with flake8
flake8 app/
```

### Database Migrations
```bash
# Create migration
alembic revision --autogenerate -m "description"

# Run migrations
alembic upgrade head

# Rollback
alembic downgrade -1
```

### Adding New Endpoints

1. **Create Schema** (`app/schemas/`)
```python
from pydantic import BaseModel

class NewFeatureCreate(BaseModel):
    name: str
    description: str
```

2. **Create Model** (`app/models/`)
```python
from sqlalchemy import Column, Integer, String
from app.database import Base

class NewFeature(Base):
    __tablename__ = "new_features"
    id = Column(Integer, primary_key=True)
    name = Column(String, nullable=False)
```

3. **Create Route** (`app/routes/`)
```python
from fastapi import APIRouter, Depends

router = APIRouter(prefix="/api/new-feature", tags=["new-feature"])

@router.post("/")
async def create_feature(feature: NewFeatureCreate):
    return {"status": "created"}
```

4. **Register Route** (`app/main.py`)
```python
from app.routes import new_feature
app.include_router(new_feature.router)
```

---

## 📊 Monitoring

### Logging
```python
import logging
logger = logging.getLogger(__name__)
logger.info("Request received")
logger.error("Error occurred", exc_info=True)
```

### Health Check
```bash
curl http://localhost:8000/health
```

### Metrics
- Request count
- Response time
- Error rate
- Active connections

---

## 🤝 Contributing

1. Follow PEP 8 style guide
2. Write tests for new features
3. Update documentation
4. Use type hints
5. Add docstrings to functions

---

## 📚 Additional Resources

- [FastAPI Documentation](https://fastapi.tiangolo.com)
- [SQLAlchemy Documentation](https://docs.sqlalchemy.org)
- [Pydantic Documentation](https://docs.pydantic.dev)
- [JWT Documentation](https://jwt.io)
- [Python Best Practices](https://docs.python-guide.org)

---

## 🐛 Troubleshooting

### Database Locked Error
```bash
# Stop all running instances
# Delete database file
rm careflowai.db
# Reinitialize
python scripts/init_db.py
```

### Import Errors
```bash
# Ensure virtual environment is activated
# Reinstall dependencies
pip install -r requirements.txt --force-reinstall
```

### Port Already in Use
```bash
# Windows
netstat -ano | findstr :8000
taskkill /PID <pid> /F

# macOS/Linux
lsof -ti:8000 | xargs kill -9
```

---

Built with care for better healthcare.
