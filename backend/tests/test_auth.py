"""
Test authentication functions
"""
import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
from passlib.context import CryptContext
import os
from dotenv import load_dotenv

load_dotenv()

MONGODB_URL = os.getenv("MONGODB_URL", "mongodb://localhost:27017")
DATABASE_NAME = os.getenv("DATABASE_NAME", "careflowai")

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


async def test_login():
    """Test login process"""
    client = AsyncIOMotorClient(MONGODB_URL)
    db = client[DATABASE_NAME]

    # Test credentials
    email = "patient@test.com"
    password = "password123"
    role = "patient"

    print(f"Testing login for: {email}")
    print(f"Looking up user in database...")

    # Find user
    user = await db.users.find_one({"email": email})

    if not user:
        print(f"[ERROR] User not found: {email}")
        client.close()
        return

    print(f"[OK] User found:")
    print(f"  - Email: {user['email']}")
    print(f"  - Name: {user['name']}")
    print(f"  - Role: {user['role']}")
    print(f"  - Hashed password: {user['hashed_password'][:20]}...")

    # Verify password
    print(f"\nTesting password verification...")
    is_valid = pwd_context.verify(password, user["hashed_password"])

    if is_valid:
        print(f"[OK] Password is correct!")
    else:
        print(f"[ERROR] Password is incorrect!")

    # Verify role
    print(f"\nTesting role verification...")
    if user["role"] == role:
        print(f"[OK] Role matches: {role}")
    else:
        print(f"[ERROR] Role mismatch! Expected: {role}, Got: {user['role']}")

    client.close()
    print("\nTest complete!")


if __name__ == "__main__":
    asyncio.run(test_login())
