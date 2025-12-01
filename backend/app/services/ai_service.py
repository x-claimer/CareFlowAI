"""
AI Service Module
This module integrates with Google Gemini API for AI-powered health analysis and medical tutoring.
"""
import uuid
import os
from typing import List
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()

# Configure Gemini API
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GEMINI_REPORT_ANALYSIS_MODEL = os.getenv("GEMINI_REPORT_ANALYSIS_MODEL", "gemini-2.5-flash")
GEMINI_TUTOR_MODEL = os.getenv("GEMINI_TUTOR_MODEL", "gemini-2.5-flash")

if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)


class AIService:
    @staticmethod
    async def analyze_health_report(file_name: str, file_content: bytes) -> dict:
        """
        AI-powered health report analysis using Google Gemini
        Analyzes medical reports (PDF/images) and extracts key health metrics
        """
        if not GEMINI_API_KEY:
            # Fallback response if API key not configured
            return {
                "analysis": "Please configure GEMINI_API_KEY to enable AI-powered health report analysis.",
                "summary": "API key configuration required",
                "file_name": file_name,
                "metrics": [],
                "recommendations": ["Configure your Gemini API key in .env file"],
            }

        try:
            # Initialize Gemini model for report analysis (multimodal)
            model = genai.GenerativeModel(GEMINI_REPORT_ANALYSIS_MODEL)

            # Determine file type and prepare content
            file_extension = file_name.lower().split('.')[-1]

            # For images (JPEG, PNG)
            if file_extension in ['jpg', 'jpeg', 'png']:
                import io
                from PIL import Image

                # Load image from bytes
                image = Image.open(io.BytesIO(file_content))

                # Create detailed prompt for health report analysis
                prompt = """You are an expert medical AI assistant analyzing a health report image.

Please provide a comprehensive analysis in the following JSON format:

{
  "summary": "A brief 2-3 sentence summary of the overall health status",
  "analysis": "Detailed analysis of the health report findings (4-6 sentences)",
  "metrics": [
    {
      "name": "Metric name (e.g., Blood Pressure, BMI, Cholesterol)",
      "value": "The measured value",
      "unit": "Unit of measurement",
      "status": "normal/warning/critical",
      "reference_range": "Normal reference range",
      "interpretation": "What this value means in simple terms"
    }
  ],
  "recommendations": [
    "Specific recommendation 1",
    "Specific recommendation 2",
    "Specific recommendation 3"
  ]
}

Extract ALL visible health metrics from the report. Common metrics to look for:
- Blood Pressure (Systolic/Diastolic)
- Heart Rate / Pulse
- BMI (Body Mass Index)
- Body Fat Percentage
- Cholesterol (Total, LDL, HDL, Triglycerides)
- Blood Sugar / Glucose (Fasting, HbA1c)
- Hemoglobin
- White Blood Cell Count
- Red Blood Cell Count
- Platelet Count
- Liver Function (ALT, AST, ALP)
- Kidney Function (Creatinine, BUN, eGFR)
- Thyroid (TSH, T3, T4)
- Vitamin levels (D, B12, etc.)
- Electrolytes (Sodium, Potassium, etc.)

For each metric found:
- Determine if it's normal, warning, or critical based on standard medical ranges
- Provide patient-friendly interpretation
- Include reference ranges when visible

Provide actionable, specific recommendations based on the findings.
Use simple, patient-friendly language throughout."""

                # Generate response with image
                response = model.generate_content([prompt, image])

            # For PDFs or other formats
            else:
                # For PDFs, we'll analyze text content
                prompt = f"""You are an expert medical AI assistant analyzing a health report document: {file_name}

Based on the document, provide a comprehensive analysis in the following JSON format:

{{
  "summary": "A brief 2-3 sentence summary of the overall health status",
  "analysis": "Detailed analysis of the health report findings (4-6 sentences)",
  "metrics": [
    {{
      "name": "Metric name",
      "value": "The measured value",
      "unit": "Unit of measurement",
      "status": "normal/warning/critical",
      "reference_range": "Normal reference range",
      "interpretation": "Patient-friendly explanation"
    }}
  ],
  "recommendations": [
    "Specific actionable recommendation 1",
    "Specific actionable recommendation 2",
    "Specific actionable recommendation 3"
  ]
}}

Extract health metrics and provide detailed analysis with patient-friendly recommendations."""

                response = model.generate_content(prompt)

            # Parse the response
            response_text = response.text.strip()

            # Try to extract JSON from response
            import json
            import re

            # Find JSON in the response (it might be wrapped in markdown code blocks)
            json_match = re.search(r'```json\s*(.*?)\s*```', response_text, re.DOTALL)
            if json_match:
                json_str = json_match.group(1)
            else:
                # Try to find raw JSON
                json_match = re.search(r'\{.*\}', response_text, re.DOTALL)
                json_str = json_match.group(0) if json_match else response_text

            try:
                parsed_response = json.loads(json_str)

                return {
                    "analysis": parsed_response.get("analysis", response_text),
                    "summary": parsed_response.get("summary", "Health report analyzed successfully"),
                    "file_name": file_name,
                    "metrics": parsed_response.get("metrics", []),
                    "recommendations": parsed_response.get("recommendations", []),
                }
            except json.JSONDecodeError:
                # If JSON parsing fails, return the text response with basic structure
                return {
                    "analysis": response_text,
                    "summary": "Health report analyzed - see detailed analysis below",
                    "file_name": file_name,
                    "metrics": [],
                    "recommendations": ["Consult with your healthcare provider for personalized advice"],
                }

        except Exception as e:
            # Fallback response on error
            return {
                "analysis": f"I encountered an issue analyzing the health report: {str(e)}. Please ensure the image is clear and contains visible health metrics.",
                "summary": "Analysis error occurred",
                "file_name": file_name,
                "metrics": [],
                "recommendations": [
                    "Ensure the report image is clear and readable",
                    "Try uploading a higher quality image",
                    "Consult your healthcare provider directly",
                ],
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
        AI-powered medical term search using Google Gemini
        Provides detailed medical information and examples
        """
        if not GEMINI_API_KEY:
            # Fallback to simulated response if API key not configured
            return {
                "term": query,
                "definition": f"{query} is a medical term. Please configure GEMINI_API_KEY for detailed AI-powered explanations.",
                "examples": [
                    "Configure your Gemini API key in .env file",
                    "GEMINI_API_KEY=your_api_key_here",
                    "Restart the backend server to apply changes",
                ],
            }

        try:
            # Initialize Gemini model for medical tutor
            model = genai.GenerativeModel(GEMINI_TUTOR_MODEL)

            # Create a detailed prompt for medical term explanation
            prompt = f"""You are a medical tutor AI assistant. Explain the medical term or health concept: "{query}"

Provide a clear, comprehensive explanation in 2-4 paragraphs that a patient can understand.

Guidelines:
- Use simple, friendly language while maintaining medical accuracy
- Explain what the term means and why it's important
- Include relevant context about causes, symptoms, or significance
- Mention related concepts naturally within the paragraphs
- Do NOT use markdown formatting (no asterisks, bold, italics, bullets, or numbered lists)
- Write in flowing paragraphs only
- Be conversational and patient-focused

Write your response as plain text paragraphs without any special formatting."""

            # Generate response
            response = model.generate_content(prompt)
            response_text = response.text

            # Clean up the response text
            import re

            # Remove markdown formatting (**, *, _)
            cleaned_text = re.sub(r'\*\*|\*|_', '', response_text)

            # Remove any remaining section headers like "DEFINITION:" or "EXAMPLES:"
            cleaned_text = re.sub(r'(DEFINITION|EXAMPLES):\s*', '', cleaned_text, flags=re.IGNORECASE)

            # Clean up extra whitespace
            cleaned_text = re.sub(r'\n\s*\n\s*\n', '\n\n', cleaned_text).strip()

            return {
                "term": query,
                "definition": cleaned_text,
                "examples": [],  # No examples, just the definition paragraph
            }

        except Exception as e:
            # Fallback response on error
            return {
                "term": query,
                "definition": f"I encountered an issue retrieving information about {query}. This could be a medical term, condition, or health concept. Please try rephrasing your search or consult a healthcare professional for accurate information.",
                "examples": [
                    f"Error: {str(e)}",
                    "Try searching with different terms or more specific keywords",
                    "Consult your healthcare provider for medical advice",
                ],
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
