"""
Test Pydantic models
"""
from app.schemas.user import UserResponse, Token

print("Testing Pydantic models...")

# Test UserResponse
try:
    user_data = {
        "id": "6925333d2078bff75aae900c",
        "email": "patient@test.com",
        "name": "patient",
        "role": "patient"
    }
    user = UserResponse(**user_data)
    print(f"[OK] UserResponse created: {user}")
except Exception as e:
    print(f"[ERROR] UserResponse creation failed: {e}")

# Test Token
try:
    token_data = {
        "access_token": "test_token",
        "token_type": "bearer",
        "user": user
    }
    token = Token(**token_data)
    print(f"[OK] Token created: {token}")
    print(f"Token dict: {token.model_dump()}")
except Exception as e:
    print(f"[ERROR] Token creation failed: {e}")

print("\nTest complete!")
