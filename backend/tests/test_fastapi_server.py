"""
Minimal FastAPI server to test login endpoint
"""
from fastapi import FastAPI, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorClient
from passlib.context import CryptContext
from jose import jwt
from datetime import datetime, timedelta
from pydantic import BaseModel, EmailStr
from typing import Literal
import os
from dotenv import load_dotenv
import traceback

load_dotenv()

MONGODB_URL = os.getenv("MONGODB_URL", "mongodb://localhost:27017")
DATABASE_NAME = os.getenv("DATABASE_NAME", "careflowai")
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-change-this-in-production")
ALGORITHM = os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "30"))

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

app = FastAPI()

# MongoDB client
client = AsyncIOMotorClient(MONGODB_URL)
db = client[DATABASE_NAME]


class UserLogin(BaseModel):
    email: EmailStr
    password: str
    role: Literal["patient", "doctor", "receptionist"]


class UserResponse(BaseModel):
    id: str
    email: str
    name: str
    role: str


class Token(BaseModel):
    access_token: str
    token_type: str
    user: UserResponse


@app.post("/test-login")
async def test_login(user_credentials: UserLogin):
    """
    Test login endpoint with detailed error logging
    """
    try:
        print(f"\n[1] Received login request for: {user_credentials.email}")

        # Find user
        print(f"[2] Finding user in database...")
        user = await db.users.find_one({"email": user_credentials.email})

        if not user:
            print(f"[ERROR] User not found")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found",
            )

        print(f"[3] User found: {user['email']}")

        # Verify password
        print(f"[4] Verifying password...")
        if not pwd_context.verify(user_credentials.password, user["hashed_password"]):
            print(f"[ERROR] Password incorrect")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect password",
            )

        print(f"[5] Password verified")

        # Verify role
        print(f"[6] Verifying role...")
        if user["role"] != user_credentials.role:
            print(f"[ERROR] Role mismatch: {user['role']} != {user_credentials.role}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Role mismatch",
            )

        print(f"[7] Role verified: {user['role']}")

        # Create access token
        print(f"[8] Creating access token...")
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        to_encode = {"sub": user["email"], "role": user["role"], "exp": expire}
        access_token = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

        print(f"[9] Token created")

        # Create user response
        print(f"[10] Creating UserResponse...")
        user_response = UserResponse(
            id=str(user["_id"]),
            email=user["email"],
            name=user["name"],
            role=user["role"],
        )

        print(f"[11] UserResponse created")

        # Create token response
        print(f"[12] Creating Token response...")
        token_response = Token(
            access_token=access_token,
            token_type="bearer",
            user=user_response,
        )

        print(f"[13] Token response created")
        print(f"[SUCCESS] Login successful for {user['email']}")

        return token_response

    except HTTPException:
        raise
    except Exception as e:
        print(f"\n[FATAL ERROR] Exception occurred:")
        print(f"Error type: {type(e).__name__}")
        print(f"Error message: {str(e)}")
        print(f"Traceback:")
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Internal error: {str(e)}",
        )


@app.get("/")
async def root():
    return {"message": "Test FastAPI server"}


if __name__ == "__main__":
    import uvicorn
    print(f"Starting test server...")
    print(f"MongoDB URL: {MONGODB_URL}")
    print(f"Database: {DATABASE_NAME}")
    uvicorn.run(app, host="127.0.0.1", port=8001, log_level="info")
