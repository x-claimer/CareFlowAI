"""
Seed script to add sample appointments to the database
"""
import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
from bson import ObjectId
from datetime import datetime, timedelta
import os
from dotenv import load_dotenv

load_dotenv()

MONGODB_URL = os.getenv("MONGODB_URL", "mongodb://localhost:27017")
DATABASE_NAME = os.getenv("DATABASE_NAME", "careflowai")


async def seed_appointments():
    """Add sample appointments to the database"""
    client = AsyncIOMotorClient(MONGODB_URL)
    db = client[DATABASE_NAME]

    print(f"Connected to MongoDB at {MONGODB_URL}")
    print(f"Using database: {DATABASE_NAME}")

    # Sample appointments
    today = datetime.now()
    sample_appointments = [
        {
            "_id": ObjectId(),
            "patient_name": "John Doe",
            "doctor_name": "Dr. Smith",
            "date": (today + timedelta(days=1)).strftime("%Y-%m-%d"),
            "time": "09:00",
            "reason": "Regular checkup",
            "status": "scheduled",
            "created_at": datetime.utcnow(),
            "updated_at": None,
        },
        {
            "_id": ObjectId(),
            "patient_name": "Jane Smith",
            "doctor_name": "Dr. Johnson",
            "date": (today + timedelta(days=2)).strftime("%Y-%m-%d"),
            "time": "10:30",
            "reason": "Follow-up consultation",
            "status": "scheduled",
            "created_at": datetime.utcnow(),
            "updated_at": None,
        },
        {
            "_id": ObjectId(),
            "patient_name": "Bob Wilson",
            "doctor_name": "Dr. Smith",
            "date": (today + timedelta(days=3)).strftime("%Y-%m-%d"),
            "time": "14:00",
            "reason": "Blood test results review",
            "status": "scheduled",
            "created_at": datetime.utcnow(),
            "updated_at": None,
        },
        {
            "_id": ObjectId(),
            "patient_name": "Alice Brown",
            "doctor_name": "Dr. Johnson",
            "date": today.strftime("%Y-%m-%d"),
            "time": "11:00",
            "reason": "Annual physical examination",
            "status": "completed",
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow(),
        },
        {
            "_id": ObjectId(),
            "patient_name": "Charlie Davis",
            "doctor_name": "Dr. Smith",
            "date": (today - timedelta(days=1)).strftime("%Y-%m-%d"),
            "time": "15:30",
            "reason": "Dental cleaning",
            "status": "cancelled",
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow(),
        },
    ]

    # Check if appointments already exist
    existing_count = await db.appointments.count_documents({})
    if existing_count > 0:
        print(f"\nDatabase already has {existing_count} appointments.")
        response = input("Do you want to add more sample appointments? (yes/no): ")
        if response.lower() != "yes":
            print("Keeping existing appointments.")
            client.close()
            return

    # Insert sample appointments
    result = await db.appointments.insert_many(sample_appointments)
    print(f"\nCreated {len(result.inserted_ids)} sample appointments:")

    for appointment in sample_appointments:
        print(
            f"  - {appointment['patient_name']} with {appointment['doctor_name']} "
            f"on {appointment['date']} at {appointment['time']} ({appointment['status']})"
        )

    client.close()
    print("\nAppointment seeding complete!")


if __name__ == "__main__":
    asyncio.run(seed_appointments())
