"""
Script to seed the database with test users and appointments
to demonstrate all role-based access control scenarios.
"""

import asyncio
import sys
from pathlib import Path
from datetime import datetime, timedelta
from bson import ObjectId
import os
from dotenv import load_dotenv

# Add parent directory to path to import app modules
sys.path.insert(0, str(Path(__file__).parent.parent))

from motor.motor_asyncio import AsyncIOMotorClient
from app.utils.auth import get_password_hash

load_dotenv()

# MongoDB connection
MONGODB_URL = os.getenv("MONGODB_URL", "mongodb://localhost:27017")
DATABASE_NAME = os.getenv("DATABASE_NAME", "careflowai")

async def seed_database():
    """Seed the database with test data"""
    print("Connecting to MongoDB...")
    client = AsyncIOMotorClient(MONGODB_URL)
    db = client[DATABASE_NAME]

    # Clear existing data
    print("Clearing existing data...")
    await db.users.delete_many({})
    await db.appointments.delete_many({})
    await db.comments.delete_many({})

    # Create users with different roles
    print("Creating users...")

    # Patients
    patient1_id = str(ObjectId())
    patient2_id = str(ObjectId())
    patient3_id = str(ObjectId())

    # Doctors
    doctor1_id = str(ObjectId())
    doctor2_id = str(ObjectId())

    # Receptionist
    receptionist_id = str(ObjectId())

    # Admin
    admin_id = str(ObjectId())

    users = [
        # Patients
        {
            "_id": ObjectId(patient1_id),
            "name": "John Doe",
            "email": "john.doe@example.com",
            "hashed_password": get_password_hash("password123"),
            "role": "patient"
        },
        {
            "_id": ObjectId(patient2_id),
            "name": "Jane Smith",
            "email": "jane.smith@example.com",
            "hashed_password": get_password_hash("password123"),
            "role": "patient"
        },
        {
            "_id": ObjectId(patient3_id),
            "name": "Bob Wilson",
            "email": "bob.wilson@example.com",
            "hashed_password": get_password_hash("password123"),
            "role": "patient"
        },

        # Doctors
        {
            "_id": ObjectId(doctor1_id),
            "name": "Dr. Sarah Johnson",
            "email": "sarah.johnson@hospital.com",
            "hashed_password": get_password_hash("password123"),
            "role": "doctor"
        },
        {
            "_id": ObjectId(doctor2_id),
            "name": "Dr. Michael Chen",
            "email": "michael.chen@hospital.com",
            "hashed_password": get_password_hash("password123"),
            "role": "doctor"
        },

        # Receptionist
        {
            "_id": ObjectId(receptionist_id),
            "name": "Emily Davis",
            "email": "emily.davis@hospital.com",
            "hashed_password": get_password_hash("password123"),
            "role": "receptionist"
        },

        # Admin
        {
            "_id": ObjectId(admin_id),
            "name": "Admin User",
            "email": "admin@hospital.com",
            "hashed_password": get_password_hash("admin123"),
            "role": "admin"
        }
    ]

    await db.users.insert_many(users)
    print(f"Created {len(users)} users")

    # Create appointments
    print("Creating appointments...")

    base_date = datetime.now()

    appointments = [
        # Patient 1 (John Doe) appointments
        {
            "_id": ObjectId(),
            "patient_id": patient1_id,
            "patient_name": "John Doe",
            "doctor_id": doctor1_id,
            "doctor_name": "Dr. Sarah Johnson",
            "date": (base_date + timedelta(days=1)).strftime("%Y-%m-%d"),
            "time": "09:00",
            "reason": "Annual checkup",
            "status": "scheduled",
            "created_at": datetime.utcnow(),
            "updated_at": None
        },
        {
            "_id": ObjectId(),
            "patient_id": patient1_id,
            "patient_name": "John Doe",
            "doctor_id": doctor2_id,
            "doctor_name": "Dr. Michael Chen",
            "date": (base_date + timedelta(days=7)).strftime("%Y-%m-%d"),
            "time": "14:00",
            "reason": "Follow-up consultation with cardiologist",
            "status": "scheduled",
            "created_at": datetime.utcnow(),
            "updated_at": None
        },
        {
            "_id": ObjectId(),
            "patient_id": patient1_id,
            "patient_name": "John Doe",
            "doctor_id": doctor1_id,
            "doctor_name": "Dr. Sarah Johnson",
            "date": (base_date - timedelta(days=30)).strftime("%Y-%m-%d"),
            "time": "10:00",
            "reason": "Blood pressure check",
            "status": "completed",
            "created_at": datetime.utcnow(),
            "updated_at": None
        },

        # Patient 2 (Jane Smith) appointments
        {
            "_id": ObjectId(),
            "patient_id": patient2_id,
            "patient_name": "Jane Smith",
            "doctor_id": doctor1_id,
            "doctor_name": "Dr. Sarah Johnson",
            "date": (base_date + timedelta(days=2)).strftime("%Y-%m-%d"),
            "time": "11:00",
            "reason": "Diabetes management review",
            "status": "scheduled",
            "created_at": datetime.utcnow(),
            "updated_at": None
        },
        {
            "_id": ObjectId(),
            "patient_id": patient2_id,
            "patient_name": "Jane Smith",
            "doctor_id": doctor2_id,
            "doctor_name": "Dr. Michael Chen",
            "date": (base_date + timedelta(days=14)).strftime("%Y-%m-%d"),
            "time": "15:30",
            "reason": "Cardiology consultation",
            "status": "scheduled",
            "created_at": datetime.utcnow(),
            "updated_at": None
        },
        {
            "_id": ObjectId(),
            "patient_id": patient2_id,
            "patient_name": "Jane Smith",
            "doctor_id": doctor1_id,
            "doctor_name": "Dr. Sarah Johnson",
            "date": (base_date - timedelta(days=15)).strftime("%Y-%m-%d"),
            "time": "09:30",
            "reason": "General checkup",
            "status": "completed",
            "created_at": datetime.utcnow(),
            "updated_at": None
        },

        # Patient 3 (Bob Wilson) appointments
        {
            "_id": ObjectId(),
            "patient_id": patient3_id,
            "patient_name": "Bob Wilson",
            "doctor_id": doctor2_id,
            "doctor_name": "Dr. Michael Chen",
            "date": (base_date + timedelta(days=3)).strftime("%Y-%m-%d"),
            "time": "10:30",
            "reason": "Heart examination",
            "status": "scheduled",
            "created_at": datetime.utcnow(),
            "updated_at": None
        },
        {
            "_id": ObjectId(),
            "patient_id": patient3_id,
            "patient_name": "Bob Wilson",
            "doctor_id": doctor1_id,
            "doctor_name": "Dr. Sarah Johnson",
            "date": (base_date + timedelta(days=5)).strftime("%Y-%m-%d"),
            "time": "13:00",
            "reason": "Prescription refill",
            "status": "scheduled",
            "created_at": datetime.utcnow(),
            "updated_at": None
        },
        {
            "_id": ObjectId(),
            "patient_id": patient3_id,
            "patient_name": "Bob Wilson",
            "doctor_id": doctor2_id,
            "doctor_name": "Dr. Michael Chen",
            "date": (base_date - timedelta(days=7)).strftime("%Y-%m-%d"),
            "time": "11:00",
            "reason": "Initial consultation",
            "status": "cancelled",
            "created_at": datetime.utcnow(),
            "updated_at": None
        }
    ]

    result = await db.appointments.insert_many(appointments)
    print(f"Created {len(appointments)} appointments")

    # Add some sample comments
    print("Creating comments...")

    # Get first few appointment IDs for comments
    appt_docs = await db.appointments.find().limit(3).to_list(length=3)

    comments = []
    if len(appt_docs) >= 1:
        comments.append({
            "_id": ObjectId(),
            "appointment_id": str(appt_docs[0]["_id"]),
            "user_id": doctor1_id,
            "user_name": "Dr. Sarah Johnson",
            "user_role": "doctor",
            "content": "Please bring your previous medical records and current medication list.",
            "timestamp": datetime.utcnow()
        })

    if len(appt_docs) >= 2:
        comments.append({
            "_id": ObjectId(),
            "appointment_id": str(appt_docs[1]["_id"]),
            "user_id": patient1_id,
            "user_name": "John Doe",
            "user_role": "patient",
            "content": "I have some questions about the upcoming procedure.",
            "timestamp": datetime.utcnow()
        })
        comments.append({
            "_id": ObjectId(),
            "appointment_id": str(appt_docs[1]["_id"]),
            "user_id": doctor2_id,
            "user_name": "Dr. Michael Chen",
            "user_role": "doctor",
            "content": "We'll address all your questions during the appointment. Please feel free to bring a list.",
            "timestamp": datetime.utcnow()
        })

    if comments:
        await db.comments.insert_many(comments)
        print(f"Created {len(comments)} comments")

    # Print summary
    print("\n" + "="*60)
    print("DATABASE SEEDED SUCCESSFULLY!")
    print("="*60)
    print("\nTest User Credentials:")
    print("-" * 60)
    print("\nPATIENTS:")
    print("  1. John Doe")
    print("     Email: john.doe@example.com")
    print("     Password: password123")
    print("     Has appointments with both doctors")
    print()
    print("  2. Jane Smith")
    print("     Email: jane.smith@example.com")
    print("     Password: password123")
    print("     Has appointments with both doctors")
    print()
    print("  3. Bob Wilson")
    print("     Email: bob.wilson@example.com")
    print("     Password: password123")
    print("     Has appointments with both doctors")
    print()
    print("\nDOCTORS:")
    print("  1. Dr. Sarah Johnson")
    print("     Email: sarah.johnson@hospital.com")
    print("     Password: password123")
    print("     Has patients: John Doe, Jane Smith, Bob Wilson")
    print()
    print("  2. Dr. Michael Chen")
    print("     Email: michael.chen@hospital.com")
    print("     Password: password123")
    print("     Has patients: John Doe, Jane Smith, Bob Wilson")
    print()
    print("\nRECEPTIONIST:")
    print("  Emily Davis")
    print("  Email: emily.davis@hospital.com")
    print("  Password: password123")
    print("  Can manage all appointments")
    print()
    print("\nADMIN:")
    print("  Admin User")
    print("  Email: admin@hospital.com")
    print("  Password: admin123")
    print("  Full access to all features")
    print()
    print("="*60)
    print(f"\nTotal Users: {len(users)}")
    print(f"Total Appointments: {len(appointments)}")
    print(f"Total Comments: {len(comments)}")
    print("="*60)

    client.close()

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description='Seed database with test data')
    parser.add_argument('--yes', '-y', action='store_true', help='Skip confirmation prompt')
    args = parser.parse_args()

    print("\n" + "="*60)
    print("CAREFLOWAI - DATABASE SEEDING SCRIPT")
    print("="*60)
    print("\nThis will clear all existing data and create test users")
    print("and appointments for testing role-based access control.")
    print()

    if args.yes:
        asyncio.run(seed_database())
    else:
        response = input("Do you want to continue? (yes/no): ")
        if response.lower() in ['yes', 'y']:
            asyncio.run(seed_database())
        else:
            print("Seeding cancelled.")
