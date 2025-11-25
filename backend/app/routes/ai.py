from fastapi import APIRouter, Depends, File, UploadFile, HTTPException, status
from app.schemas.ai import (
    AnalyzeReportResponse,
    ChatRequest,
    ChatResponse,
    TutorSearchRequest,
    TutorSearchResponse,
    PopularTermsResponse,
)
from app.utils.auth import get_current_user
from app.services.ai_service import AIService
import os
from dotenv import load_dotenv

load_dotenv()

MAX_UPLOAD_SIZE = int(os.getenv("MAX_UPLOAD_SIZE", "10485760"))  # 10MB default

router = APIRouter(prefix="/api/ai", tags=["AI Services"])
ai_service = AIService()


@router.post("/nurse/analyze-report", response_model=AnalyzeReportResponse)
async def analyze_health_report(
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
):
    """
    AI Nurse: Analyze uploaded health report
    Accepts PDF, JPG, JPEG, PNG files (max 10MB)
    """
    # Validate file type
    allowed_types = ["application/pdf", "image/jpeg", "image/png", "image/jpg"]
    if file.content_type not in allowed_types:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid file type. Allowed: PDF, JPG, PNG",
        )

    # Read file content
    file_content = await file.read()

    # Validate file size
    if len(file_content) > MAX_UPLOAD_SIZE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"File too large. Maximum size: {MAX_UPLOAD_SIZE / 1024 / 1024}MB",
        )

    # Save file to uploads directory (optional)
    upload_dir = os.getenv("UPLOAD_DIR", "./uploads")
    os.makedirs(upload_dir, exist_ok=True)

    file_path = os.path.join(upload_dir, f"{current_user['_id']}_{file.filename}")
    with open(file_path, "wb") as f:
        f.write(file_content)

    # Analyze report using AI service
    result = await ai_service.analyze_health_report(file.filename, file_content)

    return AnalyzeReportResponse(**result)


@router.post("/nurse/chat", response_model=ChatResponse)
async def chat_with_nurse(
    chat_request: ChatRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    AI Nurse: Chat about health reports and get medical advice
    """
    result = await ai_service.chat_with_nurse(
        question=chat_request.question,
        report_context=chat_request.report_id,
    )

    return ChatResponse(**result)


@router.post("/tutor/search", response_model=TutorSearchResponse)
async def search_medical_term(
    search_request: TutorSearchRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    AI Tutor: Search for medical terms and health concepts
    """
    if not search_request.query.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Search query cannot be empty",
        )

    result = await ai_service.search_medical_term(search_request.query)

    return TutorSearchResponse(**result)


@router.get("/tutor/popular-terms", response_model=PopularTermsResponse)
async def get_popular_terms(
    current_user: dict = Depends(get_current_user),
):
    """
    AI Tutor: Get list of popular medical terms
    """
    terms = await ai_service.get_popular_terms()

    return PopularTermsResponse(terms=terms)
