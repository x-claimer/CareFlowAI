# CareFlowAI - AI Services Overview

## Two AI-Powered Healthcare Services

CareFlowAI features two distinct AI services powered by Google Gemini 2.5 Flash:

---

## 1. AI Health Report Analyzer 🏥

**Purpose**: Analyze health reports and extract key metrics with visual cards

### Features
- **Upload Health Reports**: Images (JPG, PNG) or PDFs
- **Automatic Metric Extraction**: AI identifies and extracts health metrics
- **Visual Health Cards**: Color-coded cards for each metric
  - 🟢 **Green**: Normal/Healthy range
  - 🟡 **Yellow**: Warning/Elevated
  - 🔴 **Red**: Critical/Requires attention
- **Comprehensive Analysis**: Detailed findings and explanations
- **Smart Recommendations**: Personalized action items
- **Image Preview**: See your uploaded report

### Supported Metrics
- Blood Pressure, Heart Rate, BMI
- Cholesterol (Total, LDL, HDL, Triglycerides)
- Blood Sugar/Glucose, HbA1c
- Complete Blood Count (Hemoglobin, WBC, RBC, Platelets)
- Liver Function (ALT, AST, ALP)
- Kidney Function (Creatinine, BUN, eGFR)
- Thyroid (TSH, T3, T4)
- Body Fat Percentage
- Vitamins and Electrolytes

### Tech Stack
- **Model**: `gemini-2.5-flash` (configurable)
- **Multimodal**: Processes both images and text
- **Image Processing**: Pillow (PIL)
- **Backend**: FastAPI with async processing
- **Frontend**: React with TypeScript

---

## 2. AI Health Tutor 📚

**Purpose**: Learn about medical terms and health concepts

### Features
- **Medical Term Search**: Search any healthcare term or condition
- **AI-Powered Explanations**: Clear, patient-friendly definitions
- **Practical Examples**: How terms are used in medical contexts
- **Popular Terms**: Quick access to common medical terms
- **Real-time Responses**: Instant AI-generated explanations

### Use Cases
- Understand medical jargon from doctor visits
- Learn about health conditions
- Decode medical terminology
- Educational resource for patients

### Tech Stack
- **Model**: `gemini-2.5-flash` (configurable)
- **Text-based**: Optimized prompts for medical education
- **Backend**: FastAPI REST API
- **Frontend**: React with search interface

---

## Quick Start

### 1. Setup Environment

```bash
# Backend configuration
cd backend
cp .env.example .env
```

Edit `.env`:
```env
GEMINI_API_KEY=your-gemini-api-key-here
GEMINI_REPORT_ANALYSIS_MODEL=gemini-2.5-flash
GEMINI_TUTOR_MODEL=gemini-2.5-flash
```

### 2. Install Dependencies

```bash
# Backend
cd backend
.\venv\Scripts\pip.exe install -r requirements.txt

# Frontend
cd frontend
npm install
```

### 3. Start Services

```bash
# Backend (Terminal 1)
cd backend
.\venv\Scripts\python.exe run.py

# Frontend (Terminal 2)
cd frontend
npm run dev
```

### 4. Access Application

Open: `http://localhost:5173`

Both AI services appear on the **Home Page**:
1. **AI Health Report Analyzer** - Top section
2. **AI Health Tutor** - Below analyzer

---

## API Endpoints

### Health Report Analyzer

```http
POST /api/ai/nurse/analyze-report
Authorization: Bearer <token>
Content-Type: multipart/form-data

Body: file (binary)
```

**Response**:
```json
{
  "summary": "Overall health status summary",
  "analysis": "Detailed analysis...",
  "file_name": "report.jpg",
  "metrics": [
    {
      "name": "Blood Pressure",
      "value": "120/80",
      "unit": "mmHg",
      "status": "normal",
      "reference_range": "< 120/80 mmHg",
      "interpretation": "Your blood pressure is healthy..."
    }
  ],
  "recommendations": [
    "Continue balanced diet...",
    "Exercise 30 min daily..."
  ]
}
```

### Medical Tutor

```http
POST /api/ai/tutor/search
Authorization: Bearer <token>
Content-Type: application/json

{
  "query": "hypertension"
}
```

**Response**:
```json
{
  "term": "hypertension",
  "definition": "High blood pressure condition...",
  "examples": [
    "Common usage: 'Patient diagnosed with hypertension'",
    "Related terms: cardiovascular disease, systolic pressure",
    "When to seek help: persistent headaches..."
  ]
}
```

```http
GET /api/ai/tutor/popular-terms
Authorization: Bearer <token>
```

**Response**:
```json
{
  "terms": [
    "Hypertension",
    "Diabetes",
    "Cholesterol",
    "BMI",
    "Cardiovascular"
  ]
}
```

---

## Model Configuration

Both services support model selection via environment variables:

### Available Models

| Model | Speed | Cost | Capabilities | Best For |
|-------|-------|------|--------------|----------|
| `gemini-2.5-flash` | ⚡⚡⚡ | $ | Multimodal, Text | **Recommended** - Both services |
| `gemini-1.5-flash` | ⚡⚡ | $ | Multimodal, Text | Stable alternative |
| `gemini-1.5-pro` | ⚡ | $$$ | Multimodal, Text | Complex analysis |
| `gemini-2.0-flash-exp` | ⚡⚡ | $ | Experimental | Testing |

### Change Models

Edit `backend/.env`:
```env
# Different models for different services
GEMINI_REPORT_ANALYSIS_MODEL=gemini-1.5-pro
GEMINI_TUTOR_MODEL=gemini-2.5-flash
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Frontend (React)                        │
│  ┌──────────────────────┐  ┌─────────────────────────────┐ │
│  │ AI Report Analyzer   │  │  AI Health Tutor            │ │
│  │ - File upload        │  │  - Search bar               │ │
│  │ - Health cards       │  │  - Popular terms            │ │
│  │ - Analysis display   │  │  - Results display          │ │
│  └──────────────────────┘  └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                            ↓ HTTP/REST API
┌─────────────────────────────────────────────────────────────┐
│                   Backend (FastAPI)                         │
│  ┌──────────────────────┐  ┌─────────────────────────────┐ │
│  │ /api/ai/nurse/*      │  │  /api/ai/tutor/*            │ │
│  │ - analyze-report     │  │  - search                   │ │
│  │ - chat               │  │  - popular-terms            │ │
│  └──────────────────────┘  └─────────────────────────────┘ │
│                     AI Service Layer                        │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  AIService (app/services/ai_service.py)              │  │
│  │  - analyze_health_report()                           │  │
│  │  - search_medical_term()                             │  │
│  │  - get_popular_terms()                               │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              Google Gemini AI API                           │
│  - gemini-2.5-flash (Report Analysis)                      │
│  - gemini-2.5-flash (Medical Tutor)                        │
└─────────────────────────────────────────────────────────────┘
```

---

## File Structure

```
CareFlowAI/
├── backend/
│   ├── app/
│   │   ├── services/
│   │   │   └── ai_service.py          # AI logic for both services
│   │   ├── routes/
│   │   │   └── ai.py                  # API endpoints
│   │   └── schemas/
│   │       └── ai.py                  # Data models
│   ├── .env                           # Configuration (create from .env.example)
│   └── requirements.txt               # Python dependencies
│
├── frontend/
│   └── src/
│       ├── components/
│       │   ├── AINurse.tsx           # Report Analyzer UI
│       │   └── AITutor.tsx           # Medical Tutor UI
│       └── lib/
│           └── api.ts                # API client
│
├── AI_HEALTH_REPORT_ANALYZER.md      # Report Analyzer guide
├── AI_TUTOR_SETUP.md                 # Medical Tutor guide
└── AI_SERVICES_OVERVIEW.md           # This file
```

---

## Cost & Usage

### Free Tier Limits (Gemini API)
- **60 requests/minute**
- **1,500 requests/day**
- Sufficient for development and small deployments

### Optimization Tips
1. **Cache Results**: Store common medical term searches
2. **Compress Images**: Reduce file size before upload
3. **Rate Limiting**: Implement user quotas
4. **Model Selection**: Use `gemini-2.5-flash` for best speed/cost

---

## Security & Privacy

### Data Protection
- ✅ JWT authentication required
- ✅ File validation (type, size)
- ✅ CORS configured
- ✅ Temporary file storage
- ⚠️ Health data processed via Google API

### Production Considerations
1. **HIPAA Compliance**: Requires Google BAA
2. **GDPR**: Implement data retention policies
3. **Encryption**: HTTPS, file encryption
4. **Audit Logs**: Track all API calls
5. **File Cleanup**: Auto-delete after processing

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| "Configure GEMINI_API_KEY" | Add API key to `.env` file |
| No metrics extracted | Upload higher quality image |
| Upload fails | Check file size < 10MB, format supported |
| Slow analysis | Use `gemini-2.5-flash`, compress images |
| API rate limit | Upgrade to paid tier or implement caching |

### Debug Steps
1. Check backend logs in console
2. Check browser console for frontend errors
3. Verify API key is valid
4. Test with sample reports
5. Check internet connection

---

## Documentation

- **[AI_HEALTH_REPORT_ANALYZER.md](./AI_HEALTH_REPORT_ANALYZER.md)** - Complete guide for report analyzer
- **[AI_TUTOR_SETUP.md](./AI_TUTOR_SETUP.md)** - Complete guide for medical tutor
- **[AI_SERVICES_OVERVIEW.md](./AI_SERVICES_OVERVIEW.md)** - This overview

---

## Getting Help

### Resources
- [Gemini API Documentation](https://ai.google.dev/docs)
- [Gemini Models](https://ai.google.dev/models/gemini)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [React Documentation](https://react.dev/)

### Support
1. Check troubleshooting sections in guides
2. Review backend console logs
3. Test with provided examples
4. Verify environment configuration

---

## Future Enhancements

### Planned Features
- [ ] **Trend Tracking**: Monitor metrics over time
- [ ] **Multi-Report Comparison**: Compare historical reports
- [ ] **PDF Export**: Download analysis as PDF
- [ ] **Email Reports**: Send results via email
- [ ] **Voice Input**: Speak medical terms
- [ ] **Multi-Language**: Support multiple languages
- [ ] **Mobile App**: Native iOS/Android apps
- [ ] **Wearable Integration**: Import fitness tracker data
- [ ] **Doctor Portal**: Specialized physician view
- [ ] **EHR Integration**: Connect to electronic health records

---

## License & Disclaimer

**⚠️ IMPORTANT MEDICAL DISCLAIMER**

This AI tool is provided for **informational and educational purposes only**. It does not:
- Provide medical advice, diagnosis, or treatment
- Replace consultation with qualified healthcare professionals
- Guarantee accuracy of health metric interpretations
- Constitute a doctor-patient relationship

**Always consult licensed healthcare providers for medical decisions.**

**Data Privacy Notice**: Health report data is processed by Google's Gemini AI service. Review Google's privacy policy and ensure compliance with applicable healthcare regulations (HIPAA, GDPR, etc.) in your jurisdiction.

---

**Version**: 1.0.0
**Last Updated**: 2025
**Powered by**: Google Gemini 2.5 Flash
