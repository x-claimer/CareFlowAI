"""
AI Service Module
This module contains simulated AI responses for health report analysis and medical tutoring.
In production, these would be replaced with actual AI/ML model integrations.
"""
import uuid
from typing import List


class AIService:
    @staticmethod
    async def analyze_health_report(file_name: str, file_content: bytes) -> dict:
        """
        Simulate AI analysis of a health report
        In production, this would use actual ML models or API calls to analyze medical reports
        """
        # Simulated analysis based on file name
        analysis = f"""I've analyzed your health report "{file_name}". Here's a summary:

✓ Overall health indicators appear normal
✓ Blood pressure: Within healthy range
✓ Cholesterol levels: Slightly elevated - consider dietary changes
✓ Blood sugar: Normal range
✓ Kidney function: Optimal

Would you like me to explain any specific values or provide recommendations?"""

        summary = "Health report shows generally good indicators with minor attention needed for cholesterol levels."

        return {
            "analysis": analysis,
            "summary": summary,
            "file_name": file_name,
        }

    @staticmethod
    async def chat_with_nurse(question: str, report_context: str = None) -> dict:
        """
        Simulate AI chat response from the AI Nurse
        In production, this would use conversational AI models
        """
        # Simulated contextual response
        answer = f"""I understand your question about "{question}". Based on your health report, I recommend consulting with your healthcare provider for personalized advice.

In the meantime, maintaining a balanced diet and regular exercise can help improve overall health markers. Here are some general recommendations:

• Stay hydrated - drink 8 glasses of water daily
• Incorporate more fruits and vegetables
• Regular physical activity - at least 30 minutes daily
• Get adequate sleep (7-9 hours)
• Manage stress through relaxation techniques

Is there anything specific you'd like to know more about?"""

        return {
            "answer": answer,
            "message_id": str(uuid.uuid4()),
        }

    @staticmethod
    async def search_medical_term(query: str) -> dict:
        """
        Simulate AI-powered medical term search
        In production, this would query medical databases or use NLP models
        """
        # Simulated medical knowledge base
        medical_info = {
            "hypertension": {
                "definition": "Hypertension, also known as high blood pressure, is a condition where the force of blood against artery walls is consistently too high. This can lead to serious health complications if left untreated.",
                "examples": [
                    "Common usage: 'The patient was diagnosed with hypertension during routine screening'",
                    "Related terms: cardiovascular disease, systolic pressure, diastolic pressure",
                    "When to seek help: If you experience persistent headaches, shortness of breath, or nosebleeds",
                ],
            },
            "diabetes": {
                "definition": "Diabetes is a metabolic disorder characterized by high blood sugar levels over a prolonged period. It occurs when the pancreas doesn't produce enough insulin or when the body cannot effectively use the insulin it produces.",
                "examples": [
                    "Common usage: 'Type 2 diabetes can often be managed with lifestyle changes and medication'",
                    "Related terms: insulin resistance, glucose monitoring, HbA1c levels",
                    "When to seek help: If you experience excessive thirst, frequent urination, or unexplained weight loss",
                ],
            },
            "cholesterol": {
                "definition": "Cholesterol is a waxy, fat-like substance found in your blood. While your body needs cholesterol to build healthy cells, high levels of cholesterol can increase your risk of heart disease.",
                "examples": [
                    "Common usage: 'High cholesterol levels were detected in the lipid panel test'",
                    "Related terms: LDL (bad cholesterol), HDL (good cholesterol), triglycerides",
                    "When to seek help: Regular screening is recommended, especially if you have a family history",
                ],
            },
        }

        # Check if query matches known terms (case-insensitive)
        query_lower = query.lower()
        matched_info = None

        for term, info in medical_info.items():
            if term in query_lower or query_lower in term:
                matched_info = info
                break

        # If no match, provide generic response
        if not matched_info:
            matched_info = {
                "definition": f"{query} refers to a medical condition or health-related concept. This AI-powered explanation helps you understand complex medical terminology in simple terms.",
                "examples": [
                    f"Common usage: 'The patient was diagnosed with {query}'",
                    "Related terms: cardiovascular health, preventive care, wellness",
                    f"When to seek help: If you experience symptoms related to {query}, consult your healthcare provider",
                ],
            }

        return {
            "term": query,
            "definition": matched_info["definition"],
            "examples": matched_info["examples"],
        }

    @staticmethod
    async def get_popular_terms() -> List[str]:
        """
        Get list of popular medical terms
        """
        return [
            "Hypertension",
            "Diabetes",
            "Cholesterol",
            "BMI",
            "Cardiovascular",
            "Inflammation",
        ]
