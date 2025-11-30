from pydantic import BaseModel
from typing import Literal, List, Optional
from datetime import datetime


class CommentBase(BaseModel):
    content: str


class CommentCreate(CommentBase):
    pass


class CommentResponse(CommentBase):
    id: str
    user_id: str
    user_name: str
    user_role: str
    timestamp: datetime

    class Config:
        from_attributes = True


class AppointmentBase(BaseModel):
    patient_id: str
    patient_name: str
    doctor_id: str
    doctor_name: str
    date: str
    time: str
    reason: Optional[str] = None


class AppointmentCreate(AppointmentBase):
    pass


class AppointmentUpdate(BaseModel):
    patient_id: Optional[str] = None
    patient_name: Optional[str] = None
    doctor_id: Optional[str] = None
    doctor_name: Optional[str] = None
    date: Optional[str] = None
    time: Optional[str] = None
    reason: Optional[str] = None
    status: Optional[Literal["scheduled", "completed", "cancelled"]] = None


class AppointmentResponse(AppointmentBase):
    id: str
    status: Literal["scheduled", "completed", "cancelled"]
    comments: List[CommentResponse] = []

    class Config:
        from_attributes = True
