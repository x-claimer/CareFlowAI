"""Test FastAPI endpoint directly without running server"""
import asyncio
import sys
sys.path.insert(0, 'E:\\UMD\\Data 650 - PCS1\\Project\\CareFlowAI\\backend')

from app.routes.auth import signup
from app.schemas.user import UserSignup
from app.database import connect_to_mongo, get_db

async def test_signup_endpoint():
    # Connect to MongoDB
    await connect_to_mongo()

    # Create test user data
    user_data = UserSignup(
        email="fastapi_test@example.com",
        name="FastAPI Test User",
        password="testpass123"
    )

    print(f"Testing signup endpoint with: {user_data.email}")
    print("-" * 60)

    try:
        # Get database instance
        db_gen = get_db()
        db = await db_gen.__anext__()

        # Call signup function
        result = await signup(user_data=user_data, db=db)

        print(f"SUCCESS: Signup successful!")
        print(f"  - User ID: {result.user.id}")
        print(f"  - User Name: {result.user.name}")
        print(f"  - User Email: {result.user.email}")
        print(f"  - User Role: {result.user.role}")
        print(f"  - Token: {result.access_token[:50]}...")

    except Exception as e:
        print(f"FAILED: Signup failed!")
        print(f"Error: {type(e).__name__}: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test_signup_endpoint())
