"""
Script to add admin user to the database
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


async def add_admin_user():
    """Add admin user to the database"""
    client = AsyncIOMotorClient(MONGODB_URL)
    db = client[DATABASE_NAME]

    print(f"Connected to MongoDB at {MONGODB_URL}")
    print(f"Using database: {DATABASE_NAME}")

    # Check if admin already exists
    existing_admin = await db.users.find_one({"email": "admin@test.com"})

    if existing_admin:
        print("\nAdmin user already exists!")
        print("  Email: admin@test.com")
        print("  Role: admin")
        client.close()
        return

    # Create admin user
    admin_user = {
        "_id": ObjectId(),
        "email": "admin@test.com",
        "name": "Admin User",
        "hashed_password": pwd_context.hash("password123"),
        "role": "admin",
    }

    await db.users.insert_one(admin_user)
    print("\nCreated admin user:")
    print(f"  Email: {admin_user['email']}")
    print(f"  Name: {admin_user['name']}")
    print(f"  Role: {admin_user['role']}")
    print("\nAdmin credentials:")
    print("  Email: admin@test.com")
    print("  Password: password123")
    print("  Role: admin")

    client.close()
    print("\nAdmin user creation complete!")


if __name__ == "__main__":
    asyncio.run(add_admin_user())
