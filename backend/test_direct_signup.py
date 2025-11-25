"""Direct test of signup endpoint logic"""
import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
from bson import ObjectId
from app.utils.auth import get_password_hash, create_access_token

async def test_signup_logic():
    # Connect to MongoDB
    client = AsyncIOMotorClient("mongodb://localhost:27017")
    db = client.careflowai

    try:
        # Simulate signup request
        user_data = {
            "email": "direct_test@example.com",
            "name": "Direct Test User",
            "password": "testpass123"
        }

        print(f"Testing signup for: {user_data['name']}")
        print("-" * 60)

        # Check if user already exists
        existing_user = await db.users.find_one({"email": user_data['email']})
        if existing_user:
            print(f"User already exists, deleting...")
            await db.users.delete_one({"email": user_data['email']})

        # Create new patient user
        user_id = str(ObjectId())
        user_doc = {
            "_id": ObjectId(user_id),
            "email": user_data['email'],
            "name": user_data['name'],
            "hashed_password": get_password_hash(user_data['password']),
            "role": "patient",
        }

        print(f"Inserting user into database...")
        await db.users.insert_one(user_doc)
        print(f"User inserted with ID: {user_id}")

        # Create access token
        print(f"Creating access token...")
        access_token = create_access_token(
            data={"sub": user_doc["email"], "role": user_doc["role"]}
        )
        print(f"Access token created: {access_token[:50]}...")

        # Create response
        user_response = {
            "id": str(user_doc["_id"]),
            "email": user_doc["email"],
            "name": user_doc["name"],
            "role": user_doc["role"],
        }

        token_response = {
            "access_token": access_token,
            "token_type": "bearer",
            "user": user_response,
        }

        print("\nSignup successful!")
        print(f"Response:")
        print(f"  - Access Token: {token_response['access_token'][:50]}...")
        print(f"  - Token Type: {token_response['token_type']}")
        print(f"  - User ID: {token_response['user']['id']}")
        print(f"  - User Name: {token_response['user']['name']}")
        print(f"  - User Email: {token_response['user']['email']}")
        print(f"  - User Role: {token_response['user']['role']}")

    except Exception as e:
        print(f"Error: {type(e).__name__}: {e}")
        import traceback
        traceback.print_exc()
    finally:
        client.close()

if __name__ == "__main__":
    asyncio.run(test_signup_logic())
