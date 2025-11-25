from fastapi import APIRouter, Depends, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase
from bson import ObjectId

from app.database import get_db
from app.schemas.user import UserLogin, UserSignup, UserResponse, Token
from app.utils.auth import (
    verify_password,
    get_password_hash,
    create_access_token,
    get_current_user,
)

router = APIRouter(prefix="/api/auth", tags=["Authentication"])


@router.get("/test-db")
async def test_db_connection(db: AsyncIOMotorDatabase = Depends(get_db)):
    """Test endpoint to verify database connection"""
    try:
        # Try to ping the database
        result = await db.command("ping")
        return {"status": "success", "message": "Database connection OK", "ping": result}
    except Exception as e:
        return {"status": "error", "message": str(e)}


@router.post("/signup", response_model=Token, status_code=status.HTTP_201_CREATED)
async def signup(
    user_data: UserSignup,
    db: AsyncIOMotorDatabase = Depends(get_db),
):
    """
    Signup endpoint - creates a new patient account
    """
    try:
        # Check if user already exists
        existing_user = await db.users.find_one({"email": user_data.email})

        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered",
            )

        # Create new patient user
        user_id = str(ObjectId())
        user_doc = {
            "_id": ObjectId(user_id),
            "email": user_data.email,
            "name": user_data.name,
            "hashed_password": get_password_hash(user_data.password),
            "role": "patient",  # New signups are always patients
        }

        await db.users.insert_one(user_doc)

        # Create access token
        access_token = create_access_token(
            data={"sub": user_doc["email"], "role": user_doc["role"]}
        )

        user_response = UserResponse(
            id=str(user_doc["_id"]),
            email=user_doc["email"],
            name=user_doc["name"],
            role=user_doc["role"],
        )

        return Token(
            access_token=access_token,
            token_type="bearer",
            user=user_response,
        )
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        # Log the error and return a proper error response
        print(f"Signup error: {type(e).__name__}: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Signup failed: {str(e)}",
        )


@router.post("/login", response_model=Token)
async def login(
    user_credentials: UserLogin,
    db: AsyncIOMotorDatabase = Depends(get_db),
):
    """
    Login endpoint - authenticates user and returns JWT token
    """
    user = await db.users.find_one({"email": user_credentials.email})

    # For demo purposes, if user doesn't exist, create one
    if not user:
        user_id = str(ObjectId())
        user_doc = {
            "_id": ObjectId(user_id),
            "email": user_credentials.email,
            "name": user_credentials.email.split("@")[0],
            "hashed_password": get_password_hash(user_credentials.password),
            "role": user_credentials.role,
        }
        await db.users.insert_one(user_doc)
        user = user_doc
    else:
        # Verify password
        if not verify_password(user_credentials.password, user["hashed_password"]):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect email or password",
            )

        # Verify role matches
        if user["role"] != user_credentials.role:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Role mismatch",
            )

    # Create access token
    access_token = create_access_token(
        data={"sub": user["email"], "role": user["role"]}
    )

    user_response = UserResponse(
        id=str(user["_id"]),
        email=user["email"],
        name=user["name"],
        role=user["role"],
    )

    return Token(
        access_token=access_token,
        token_type="bearer",
        user=user_response,
    )


@router.post("/logout")
async def logout(current_user: dict = Depends(get_current_user)):
    """
    Logout endpoint - invalidates token (client-side token removal)
    """
    return {"success": True, "message": "Successfully logged out"}


@router.get("/me", response_model=UserResponse)
async def get_current_user_info(current_user: dict = Depends(get_current_user)):
    """
    Get current authenticated user information
    """
    return UserResponse(
        id=str(current_user["_id"]),
        email=current_user["email"],
        name=current_user["name"],
        role=current_user["role"],
    )
