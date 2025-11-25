from pydantic import BaseModel
from typing import List, Optional


class AnalyzeReportResponse(BaseModel):
    analysis: str
    summary: str
    file_name: str


class ChatRequest(BaseModel):
    question: str
    report_id: Optional[str] = None
    conversation_history: Optional[List[dict]] = None


class ChatResponse(BaseModel):
    answer: str
    message_id: str


class TutorSearchRequest(BaseModel):
    query: str


class TutorSearchResponse(BaseModel):
    term: str
    definition: str
    examples: List[str]


class PopularTermsResponse(BaseModel):
    terms: List[str]
