from fastapi import APIRouter, Depends, HTTPException, status, Query
from motor.motor_asyncio import AsyncIOMotorDatabase
from typing import List, Optional
from bson import ObjectId
from datetime import datetime

from app.database import get_db
from app.schemas.appointment import (
    AppointmentCreate,
    AppointmentUpdate,
    AppointmentResponse,
    CommentCreate,
    CommentResponse,
)
from app.utils.auth import get_current_user, require_role

router = APIRouter(prefix="/api/appointments", tags=["Appointments"])


@router.get("", response_model=List[AppointmentResponse])
async def get_appointments(
    status_filter: Optional[str] = Query(None, alias="status"),
    patient_filter: Optional[str] = Query(None, alias="patient"),
    doctor_filter: Optional[str] = Query(None, alias="doctor"),
    db: AsyncIOMotorDatabase = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """
    Get appointments with role-based filtering:
    - Patient: Only their appointments (filtered by patient_id)
    - Doctor: Only their patients' appointments across all doctors (filtered by patient list)
    - Receptionist/Admin: All appointments with optional patient/doctor filters
    """
    query = {}
    user_role = current_user["role"]
    user_id = str(current_user["_id"])

    # Role-based filtering
    if user_role == "patient":
        # Patient can only see their own appointments
        query["patient_id"] = user_id
    elif user_role == "doctor":
        # Doctor can see all appointments for their patients (across all doctors)
        # First, get all unique patient IDs from appointments where this doctor is the doctor
        doctor_appointments = await db.appointments.find({"doctor_id": user_id}).to_list(length=None)
        patient_ids = list(set([appt["patient_id"] for appt in doctor_appointments]))

        # Now get all appointments for these patients
        if patient_ids:
            query["patient_id"] = {"$in": patient_ids}
        else:
            # Doctor has no patients yet
            query["patient_id"] = {"$in": []}
    # For receptionist and admin, no additional filter is added (they see all)

    # Additional filters
    if status_filter and status_filter != "all":
        query["status"] = status_filter

    if patient_filter:
        query["patient_id"] = patient_filter

    if doctor_filter:
        query["doctor_id"] = doctor_filter

    appointments = await db.appointments.find(query).sort("created_at", -1).to_list(length=None)

    # Fetch comments for each appointment
    response = []
    for appointment in appointments:
        comments = await db.comments.find({"appointment_id": str(appointment["_id"])}).to_list(length=None)

        response.append(
            AppointmentResponse(
                id=str(appointment["_id"]),
                patient_id=appointment["patient_id"],
                patient_name=appointment["patient_name"],
                doctor_id=appointment["doctor_id"],
                doctor_name=appointment["doctor_name"],
                date=appointment["date"],
                time=appointment["time"],
                status=appointment["status"],
                reason=appointment.get("reason"),
                comments=[
                    CommentResponse(
                        id=str(c["_id"]),
                        user_id=c["user_id"],
                        user_name=c["user_name"],
                        user_role=c["user_role"],
                        content=c["content"],
                        timestamp=c["timestamp"],
                    )
                    for c in comments
                ],
            )
        )

    return response


@router.post("", response_model=AppointmentResponse, status_code=status.HTTP_201_CREATED)
async def create_appointment(
    appointment_data: AppointmentCreate,
    db: AsyncIOMotorDatabase = Depends(get_db),
    current_user: dict = Depends(require_role("doctor", "receptionist", "admin")),
):
    """
    Create a new appointment (requires doctor, receptionist, or admin role)
    """
    appointment_doc = {
        "_id": ObjectId(),
        "patient_id": appointment_data.patient_id,
        "patient_name": appointment_data.patient_name,
        "doctor_id": appointment_data.doctor_id,
        "doctor_name": appointment_data.doctor_name,
        "date": appointment_data.date,
        "time": appointment_data.time,
        "reason": appointment_data.reason,
        "status": "scheduled",
        "created_at": datetime.utcnow(),
        "updated_at": None,
    }

    await db.appointments.insert_one(appointment_doc)

    return AppointmentResponse(
        id=str(appointment_doc["_id"]),
        patient_id=appointment_doc["patient_id"],
        patient_name=appointment_doc["patient_name"],
        doctor_id=appointment_doc["doctor_id"],
        doctor_name=appointment_doc["doctor_name"],
        date=appointment_doc["date"],
        time=appointment_doc["time"],
        status=appointment_doc["status"],
        reason=appointment_doc["reason"],
        comments=[],
    )


@router.put("/{appointment_id}", response_model=AppointmentResponse)
async def update_appointment(
    appointment_id: str,
    appointment_data: AppointmentUpdate,
    db: AsyncIOMotorDatabase = Depends(get_db),
    current_user: dict = Depends(require_role("doctor", "receptionist", "admin")),
):
    """
    Update an appointment (requires doctor, receptionist, or admin role)
    """
    if not ObjectId.is_valid(appointment_id):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid appointment ID",
        )

    appointment = await db.appointments.find_one({"_id": ObjectId(appointment_id)})

    if not appointment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Appointment not found",
        )

    # Build update document
    update_doc = {"updated_at": datetime.utcnow()}
    if appointment_data.patient_id is not None:
        update_doc["patient_id"] = appointment_data.patient_id
    if appointment_data.patient_name is not None:
        update_doc["patient_name"] = appointment_data.patient_name
    if appointment_data.doctor_id is not None:
        update_doc["doctor_id"] = appointment_data.doctor_id
    if appointment_data.doctor_name is not None:
        update_doc["doctor_name"] = appointment_data.doctor_name
    if appointment_data.date is not None:
        update_doc["date"] = appointment_data.date
    if appointment_data.time is not None:
        update_doc["time"] = appointment_data.time
    if appointment_data.reason is not None:
        update_doc["reason"] = appointment_data.reason
    if appointment_data.status is not None:
        update_doc["status"] = appointment_data.status

    await db.appointments.update_one(
        {"_id": ObjectId(appointment_id)},
        {"$set": update_doc}
    )

    # Fetch updated appointment
    updated_appointment = await db.appointments.find_one({"_id": ObjectId(appointment_id)})

    # Fetch comments
    comments = await db.comments.find({"appointment_id": appointment_id}).to_list(length=None)

    return AppointmentResponse(
        id=str(updated_appointment["_id"]),
        patient_id=updated_appointment["patient_id"],
        patient_name=updated_appointment["patient_name"],
        doctor_id=updated_appointment["doctor_id"],
        doctor_name=updated_appointment["doctor_name"],
        date=updated_appointment["date"],
        time=updated_appointment["time"],
        status=updated_appointment["status"],
        reason=updated_appointment.get("reason"),
        comments=[
            CommentResponse(
                id=str(c["_id"]),
                user_id=c["user_id"],
                user_name=c["user_name"],
                user_role=c["user_role"],
                content=c["content"],
                timestamp=c["timestamp"],
            )
            for c in comments
        ],
    )


@router.delete("/{appointment_id}")
async def delete_appointment(
    appointment_id: str,
    db: AsyncIOMotorDatabase = Depends(get_db),
    current_user: dict = Depends(require_role("doctor", "receptionist", "admin")),
):
    """
    Delete an appointment (requires doctor, receptionist, or admin role)
    """
    if not ObjectId.is_valid(appointment_id):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid appointment ID",
        )

    appointment = await db.appointments.find_one({"_id": ObjectId(appointment_id)})

    if not appointment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Appointment not found",
        )

    # Delete associated comments first
    await db.comments.delete_many({"appointment_id": appointment_id})

    # Delete appointment
    await db.appointments.delete_one({"_id": ObjectId(appointment_id)})

    return {"success": True, "message": "Appointment deleted successfully"}


@router.post("/{appointment_id}/comments", response_model=CommentResponse, status_code=status.HTTP_201_CREATED)
async def add_comment(
    appointment_id: str,
    comment_data: CommentCreate,
    db: AsyncIOMotorDatabase = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """
    Add a comment to an appointment
    """
    if not ObjectId.is_valid(appointment_id):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid appointment ID",
        )

    # Verify appointment exists
    appointment = await db.appointments.find_one({"_id": ObjectId(appointment_id)})

    if not appointment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Appointment not found",
        )

    comment_doc = {
        "_id": ObjectId(),
        "appointment_id": appointment_id,
        "user_id": str(current_user["_id"]),
        "user_name": current_user["name"],
        "user_role": current_user["role"],
        "content": comment_data.content,
        "timestamp": datetime.utcnow(),
    }

    await db.comments.insert_one(comment_doc)

    return CommentResponse(
        id=str(comment_doc["_id"]),
        user_id=comment_doc["user_id"],
        user_name=comment_doc["user_name"],
        user_role=comment_doc["user_role"],
        content=comment_doc["content"],
        timestamp=comment_doc["timestamp"],
    )
