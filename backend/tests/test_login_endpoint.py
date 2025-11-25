"""
Test login endpoint directly
"""
import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
from passlib.context import CryptContext
from jose import jwt
from datetime import datetime, timedelta
import os
from dotenv import load_dotenv

load_dotenv()

MONGODB_URL = os.getenv("MONGODB_URL", "mongodb://localhost:27017")
DATABASE_NAME = os.getenv("DATABASE_NAME", "careflowai")
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-change-this-in-production")
ALGORITHM = os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "30"))

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


async def test_login_flow():
    """Test the complete login flow"""
    client = AsyncIOMotorClient(MONGODB_URL)
    db = client[DATABASE_NAME]

    # Test credentials
    email = "patient@test.com"
    password = "password123"
    role = "patient"

    print(f"Testing login flow for: {email}")

    # Step 1: Find user
    print("\n1. Finding user in database...")
    user = await db.users.find_one({"email": email})

    if not user:
        print(f"[ERROR] User not found")
        client.close()
        return

    print(f"[OK] User found: {user['email']}")

    # Step 2: Verify password
    print("\n2. Verifying password...")
    if not pwd_context.verify(password, user["hashed_password"]):
        print("[ERROR] Password incorrect")
        client.close()
        return

    print("[OK] Password correct")

    # Step 3: Verify role
    print("\n3. Verifying role...")
    if user["role"] != role:
        print(f"[ERROR] Role mismatch: {user['role']} != {role}")
        client.close()
        return

    print(f"[OK] Role matches: {role}")

    # Step 4: Create access token
    print("\n4. Creating access token...")
    try:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        to_encode = {"sub": user["email"], "role": user["role"], "exp": expire}
        access_token = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
        print(f"[OK] Token created: {access_token[:30]}...")
    except Exception as e:
        print(f"[ERROR] Token creation failed: {e}")
        client.close()
        return

    # Step 5: Build response
    print("\n5. Building response...")
    try:
        response = {
            "access_token": access_token,
            "token_type": "bearer",
            "user": {
                "id": str(user["_id"]),
                "email": user["email"],
                "name": user["name"],
                "role": user["role"],
            }
        }
        print(f"[OK] Response built successfully")
        print(f"\nResponse:")
        print(f"  - Token type: {response['token_type']}")
        print(f"  - User ID: {response['user']['id']}")
        print(f"  - User email: {response['user']['email']}")
        print(f"  - User name: {response['user']['name']}")
        print(f"  - User role: {response['user']['role']}")
    except Exception as e:
        print(f"[ERROR] Response building failed: {e}")
        client.close()
        return

    client.close()
    print("\n[SUCCESS] Login flow completed successfully!")


if __name__ == "__main__":
    asyncio.run(test_login_flow())
