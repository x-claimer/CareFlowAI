"""Debug script to test signup endpoint directly"""
import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
from app.utils.auth import get_password_hash
from bson import ObjectId

async def test_signup():
    # Connect to MongoDB
    client = AsyncIOMotorClient("mongodb://localhost:27017")
    db = client.careflowai

    try:
        # Test password hashing
        print("Testing password hashing...")
        hashed = get_password_hash("testpass123")
        print(f"Hashed password: {hashed[:50]}...")

        # Test user creation
        print("\nTesting user creation...")
        user_id = str(ObjectId())
        user_doc = {
            "_id": ObjectId(user_id),
            "email": "debug@test.com",
            "name": "Debug User",
            "hashed_password": hashed,
            "role": "patient"
        }

        # Check if user exists
        existing = await db.users.find_one({"email": user_doc["email"]})
        if existing:
            print(f"User already exists, deleting...")
            await db.users.delete_one({"email": user_doc["email"]})

        # Insert user
        result = await db.users.insert_one(user_doc)
        print(f"User created with ID: {result.inserted_id}")

        # Verify user was created
        created_user = await db.users.find_one({"_id": ObjectId(user_id)})
        if created_user:
            print(f"✓ User verified in database: {created_user['email']}")
        else:
            print("✗ User not found in database")

    except Exception as e:
        print(f"Error: {type(e).__name__}: {e}")
        import traceback
        traceback.print_exc()
    finally:
        client.close()

if __name__ == "__main__":
    asyncio.run(test_signup())
