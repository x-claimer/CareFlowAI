# CareFlowAI Backend

AI-Powered Healthcare Management System Backend built with FastAPI.

## Features

- **Authentication**: JWT-based authentication with role-based access control
- **Appointments**: CRUD operations for managing appointments
- **AI Nurse**: Health report analysis and chat functionality
- **AI Tutor**: Medical terminology search and education
- **Comments**: Collaborative appointment notes

## Tech Stack

- **Framework**: FastAPI
- **Database**: MongoDB (async with Motor)
- **Authentication**: JWT (python-jose)
- **Password Hashing**: bcrypt (passlib)
- **File Upload**: python-multipart

## Setup

### 1. Install MongoDB

**IMPORTANT**: You need MongoDB installed and running before starting the backend.

See [MONGODB_SETUP.md](MONGODB_SETUP.md) for detailed installation instructions for:
- Windows, macOS, Linux (local installation)
- MongoDB Atlas (cloud - free tier)
- Docker (quick setup)

Quick start with Docker:
```bash
docker run -d --name mongodb -p 27017:27017 mongo:latest
```

### 2. Install Dependencies

```bash
cd backend
pip install -r requirements.txt
```

### 3. Configure Environment

Copy `.env.example` to `.env` and update the values:

```bash
cp .env.example .env
```

Default MongoDB configuration (already set):
```
MONGODB_URL=mongodb://localhost:27017
DATABASE_NAME=careflowai
```

### 4. Run the Application

```bash
python run.py
```

Or with uvicorn directly:

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at: `http://localhost:8000`

### 4. API Documentation

Interactive API documentation is available at:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## API Endpoints

### Authentication
- `POST /api/auth/login` - Login and get JWT token
- `POST /api/auth/logout` - Logout
- `GET /api/auth/me` - Get current user info

### Appointments
- `GET /api/appointments` - Get all appointments (with optional status filter)
- `POST /api/appointments` - Create appointment (doctor/receptionist only)
- `PUT /api/appointments/{id}` - Update appointment (doctor/receptionist only)
- `DELETE /api/appointments/{id}` - Delete appointment (doctor/receptionist only)
- `POST /api/appointments/{id}/comments` - Add comment to appointment

### AI Nurse
- `POST /api/ai/nurse/analyze-report` - Upload and analyze health report
- `POST /api/ai/nurse/chat` - Chat with AI Nurse

### AI Tutor
- `POST /api/ai/tutor/search` - Search medical terms
- `GET /api/ai/tutor/popular-terms` - Get popular medical terms

## User Roles

- **Patient**: Can view appointments, upload reports, use AI features
- **Doctor**: All patient permissions + CRUD appointments
- **Receptionist**: CRUD appointments

## Database

The application uses MongoDB with async support via Motor driver. Collections are created automatically when you first use the API.

**Collections:**
- `users` - User accounts (patients, doctors, receptionists)
- `appointments` - Appointment records with status tracking
- `comments` - Comments associated with appointments

**Connection:**
- Default: `mongodb://localhost:27017`
- Database name: `careflowai`
- Collections are schema-less (NoSQL)

## File Uploads

Health reports are saved to the `uploads/` directory. Supported formats:
- PDF (.pdf)
- Images (.jpg, .jpeg, .png)
- Max size: 10MB

## Development

### Project Structure

```
backend/
├── app/
│   ├── models/          # SQLAlchemy models
│   ├── schemas/         # Pydantic schemas
│   ├── routes/          # API route handlers
│   ├── services/        # Business logic
│   ├── utils/           # Utility functions
│   ├── database.py      # Database configuration
│   └── main.py          # FastAPI application
├── uploads/             # Uploaded files
├── requirements.txt     # Python dependencies
├── run.py              # Run script
└── .env                # Environment variables
```

## Notes

- **MongoDB Required**: Ensure MongoDB is running before starting the server. See [MONGODB_SETUP.md](MONGODB_SETUP.md)
- The AI services currently use simulated responses. In production, integrate with actual AI/ML models.
- For demo purposes, the login endpoint auto-creates users if they don't exist.
- Change the `SECRET_KEY` in production for security.
- MongoDB collections are created automatically on first use.
