from pydantic import BaseModel, EmailStr
from typing import Literal


class UserBase(BaseModel):
    email: EmailStr
    name: str
    role: Literal["patient", "doctor", "receptionist", "admin"]


class UserCreate(UserBase):
    password: str


class UserSignup(BaseModel):
    email: EmailStr
    name: str
    password: str


class UserLogin(BaseModel):
    email: EmailStr
    password: str
    role: Literal["patient", "doctor", "receptionist", "admin"]


class UserResponse(UserBase):
    id: str

    class Config:
        from_attributes = True


class Token(BaseModel):
    access_token: str
    token_type: str
    user: UserResponse


class TokenData(BaseModel):
    email: str | None = None
    role: str | None = None
