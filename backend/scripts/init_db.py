"""
Database initialization script
Creates test users for development
"""
import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
from passlib.context import CryptContext
from bson import ObjectId
import os
import warnings
from dotenv import load_dotenv

# Suppress passlib bcrypt version warning
warnings.filterwarnings("ignore", message=".*bcrypt.*")

load_dotenv()

MONGODB_URL = os.getenv("MONGODB_URL", "mongodb://localhost:27017")
DATABASE_NAME = os.getenv("DATABASE_NAME", "careflowai")

pwd_context = CryptContext(
    schemes=["bcrypt"],
    deprecated="auto",
    bcrypt__rounds=12,
    bcrypt__truncate_error=True
)


async def init_database():
    """Initialize database with test users"""
    client = AsyncIOMotorClient(MONGODB_URL)
    db = client[DATABASE_NAME]

    print(f"Connected to MongoDB at {MONGODB_URL}")
    print(f"Using database: {DATABASE_NAME}")

    # Test users
    test_users = [
        {
            "_id": ObjectId(),
            "email": "patient@test.com",
            "name": "Test Patient",
            "hashed_password": pwd_context.hash("password123"),
            "role": "patient",
        },
        {
            "_id": ObjectId(),
            "email": "doctor@test.com",
            "name": "Dr. Test",
            "hashed_password": pwd_context.hash("password123"),
            "role": "doctor",
        },
        {
            "_id": ObjectId(),
            "email": "receptionist@test.com",
            "name": "Test Receptionist",
            "hashed_password": pwd_context.hash("password123"),
            "role": "receptionist",
        },
        {
            "_id": ObjectId(),
            "email": "admin@test.com",
            "name": "Admin User",
            "hashed_password": pwd_context.hash("password123"),
            "role": "admin",
        },
    ]

    # Check if users already exist
    existing_count = await db.users.count_documents({})
    if existing_count > 0:
        print(f"\nDatabase already has {existing_count} users.")
        response = input("Do you want to reset the database? (yes/no): ")
        if response.lower() == "yes":
            await db.users.delete_many({})
            print("Deleted existing users.")
        else:
            print("Keeping existing users.")
            client.close()
            return

    # Insert test users
    result = await db.users.insert_many(test_users)
    print(f"\nCreated {len(result.inserted_ids)} test users:")

    for user in test_users:
        print(f"  - {user['email']} ({user['role']})")

    print("\nTest credentials:")
    print("  Email: patient@test.com, doctor@test.com, receptionist@test.com, or admin@test.com")
    print("  Password: password123")
    print("  Role: patient, doctor, receptionist, or admin (must match email)")

    client.close()
    print("\nDatabase initialization complete!")


if __name__ == "__main__":
    asyncio.run(init_database())
