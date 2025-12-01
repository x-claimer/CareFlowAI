# AI Health Report Analyzer - Complete Guide

This guide explains how to use the AI Health Report Analyzer powered by Google Gemini 2.5 Flash for analyzing medical reports and extracting key health metrics.

## Overview

The AI Health Report Analyzer provides two main AI-powered services:

### 1. **AI Health Report Analyzer** (AI Nurse)
- Upload health reports (images/PDFs)
- AI extracts key health metrics
- Visual health metric cards with status indicators
- Detailed analysis and summary
- Personalized recommendations
- Supports blood work, vitals, imaging reports, etc.

### 2. **AI Health Tutor**
- Search for medical terms and health concepts
- Get patient-friendly explanations
- Learn about medical jargon
- Understand healthcare terminology

## Features

### Health Report Analysis
- **Multimodal AI Processing**: Analyzes both images and PDFs
- **Metric Extraction**: Automatically identifies and extracts health metrics:
  - Blood Pressure (Systolic/Diastolic)
  - BMI (Body Mass Index)
  - Body Fat Percentage
  - Heart Rate/Pulse
  - Cholesterol (Total, LDL, HDL, Triglycerides)
  - Blood Sugar/Glucose (Fasting, HbA1c)
  - Hemoglobin, WBC, RBC, Platelets
  - Liver Function (ALT, AST, ALP)
  - Kidney Function (Creatinine, BUN, eGFR)
  - Thyroid (TSH, T3, T4)
  - Vitamins and Electrolytes

- **Visual Health Cards**: Each metric displayed with:
  - Metric name and value
  - Unit of measurement
  - Status indicator (Normal/Warning/Critical)
  - Color-coded cards (Green/Yellow/Red)
  - Reference ranges
  - Patient-friendly interpretation
  - Contextual icons

- **AI-Powered Analysis**:
  - Comprehensive summary
  - Detailed findings
  - Actionable recommendations
  - Medical context and explanations

## Setup Instructions

### Prerequisites

1. **Google Gemini API Key**: Required for AI analysis
2. **Python 3.8+** with virtual environment
3. **Node.js 18+** for frontend

### Step 1: Configure Environment Variables

Edit `backend/.env`:

```env
# Google Gemini AI API Configuration
GEMINI_API_KEY=your-actual-gemini-api-key

# AI Model Selection
GEMINI_REPORT_ANALYSIS_MODEL=gemini-2.5-flash
GEMINI_TUTOR_MODEL=gemini-2.5-flash
```

**Available Models:**
- `gemini-2.5-flash` - Latest, fastest, best for multimodal (recommended)
- `gemini-1.5-flash` - Stable alternative
- `gemini-1.5-pro` - More powerful but slower
- `gemini-2.0-flash-exp` - Experimental 2.0

### Step 2: Install Dependencies

Backend:
```bash
cd backend
.\venv\Scripts\pip.exe install -r requirements.txt
```

This installs:
- `google-generativeai==0.8.3` - Gemini SDK
- `Pillow==10.4.0` - Image processing
- Other required packages

Frontend:
```bash
cd frontend
npm install
```

### Step 3: Start the Services

Backend:
```bash
cd backend
.\venv\Scripts\python.exe run.py
```

Frontend:
```bash
cd frontend
npm run dev
```

## Using the Health Report Analyzer

### Web Interface

1. **Navigate to Home Page**: Open `http://localhost:5173`

2. **Login**: Sign in with your credentials

3. **Find AI Health Report Analyzer**: Located on the home page (first AI service)

4. **Upload Report**:
   - Click the upload area
   - Select a health report file (JPG, PNG, or PDF)
   - Max file size: 10MB
   - Supported formats: `.jpg`, `.jpeg`, `.png`, `.pdf`

5. **View Results**:
   - **Summary Card**: Quick overview of health status
   - **Health Metric Cards**: Individual cards for each metric with:
     - Visual status indicators (green/yellow/red)
     - Metric values and reference ranges
     - Interpretations
   - **Detailed Analysis**: Comprehensive AI analysis
   - **Recommendations**: Personalized action items

### Best Practices for Report Upload

1. **Image Quality**:
   - Use high-resolution scans or photos
   - Ensure text is clearly readable
   - Avoid glare or shadows
   - Straight orientation (not tilted)

2. **Report Types Supported**:
   - Complete Blood Count (CBC)
   - Comprehensive Metabolic Panel (CMP)
   - Lipid Panel
   - Thyroid Function Tests
   - Liver Function Tests
   - Kidney Function Tests
   - HbA1c / Glucose Tests
   - Vitals Reports
   - Body Composition Analysis

3. **Multiple Page Reports**:
   - For multi-page PDFs: Upload as single PDF
   - For multiple images: Upload one at a time

## API Endpoints

### Analyze Health Report

```http
POST /api/ai/nurse/analyze-report
Authorization: Bearer <your-token>
Content-Type: multipart/form-data

file: <binary-file-data>
```

**Response:**
```json
{
  "analysis": "Detailed AI analysis of the health report...",
  "summary": "Brief 2-3 sentence summary",
  "file_name": "report.jpg",
  "metrics": [
    {
      "name": "Blood Pressure",
      "value": "120/80",
      "unit": "mmHg",
      "status": "normal",
      "reference_range": "< 120/80 mmHg",
      "interpretation": "Your blood pressure is within the normal healthy range..."
    },
    {
      "name": "BMI",
      "value": "24.5",
      "unit": "kg/m²",
      "status": "normal",
      "reference_range": "18.5-24.9 kg/m²",
      "interpretation": "Your BMI indicates a healthy weight range..."
    }
  ],
  "recommendations": [
    "Continue maintaining a balanced diet with plenty of fruits and vegetables",
    "Aim for 30 minutes of moderate exercise 5 days per week",
    "Schedule regular check-ups every 6-12 months"
  ]
}
```

### Health Metric Status

- `normal`: Metric is within healthy reference range (Green cards)
- `warning`: Metric is slightly outside normal range (Yellow cards)
- `critical`: Metric requires immediate attention (Red cards)

## Architecture

### Backend Processing Flow

```
1. File Upload → FastAPI endpoint receives file
2. File Validation → Check type, size
3. File Processing →
   - Images: Load with Pillow, convert to format for Gemini
   - PDFs: Extract for analysis
4. Gemini API Call →
   - Send multimodal prompt with image/document
   - Request structured JSON response
5. Response Parsing →
   - Extract JSON from response
   - Validate metrics structure
   - Handle fallbacks
6. Return Results → Send to frontend
```

### Prompt Engineering

The system uses carefully crafted prompts that:
- Request specific JSON structure
- List all possible health metrics to look for
- Ask for status classification
- Request patient-friendly interpretations
- Include reference ranges
- Generate actionable recommendations

Example prompt structure:
```
You are an expert medical AI assistant analyzing a health report image.

Provide analysis in JSON format with:
- summary: brief overall health status
- analysis: detailed findings
- metrics: array of health metrics with:
  - name, value, unit
  - status (normal/warning/critical)
  - reference_range
  - interpretation (patient-friendly)
- recommendations: actionable advice

Extract ALL visible metrics from: [list of metrics]
```

### Frontend Component Architecture

**AINurse Component** (`frontend/src/components/AINurse.tsx`):
- File upload handling
- Image preview
- API integration
- Results display:
  - Summary card
  - Metric cards grid
  - Analysis section
  - Recommendations
  - Disclaimer

**Color-Coded Cards**:
- Normal: Green gradient (`from-green-900/30 to-green-800/20`)
- Warning: Yellow gradient (`from-yellow-900/30 to-yellow-800/20`)
- Critical: Red gradient (`from-red-900/30 to-red-800/20`)

**Dynamic Icons**:
- Heart: Blood pressure, cardiovascular metrics
- Weight: BMI, body composition
- Activity: Heart rate, pulse
- Droplet: Blood sugar, cholesterol
- Zap: Default for other metrics

## Customization

### Change AI Models

Edit `backend/.env`:
```env
# Use different model for report analysis
GEMINI_REPORT_ANALYSIS_MODEL=gemini-1.5-pro

# Use different model for tutor
GEMINI_TUTOR_MODEL=gemini-2.5-flash
```

### Modify Metric Detection

Edit `backend/app/services/ai_service.py` in the prompt to add/remove metrics:

```python
prompt = """...
Extract ALL visible health metrics from the report. Common metrics to look for:
- Your Custom Metric 1
- Your Custom Metric 2
...
"""
```

### Customize Status Thresholds

The AI determines status based on medical standards. To override, modify the response parsing logic in `ai_service.py`:

```python
# Custom logic to override AI-determined status
if metric['name'] == 'Custom Metric':
    if float(metric['value']) > threshold:
        metric['status'] = 'warning'
```

### Add Custom Metric Icons

Edit `frontend/src/components/AINurse.tsx`:

```typescript
const getMetricIcon = (metricName: string) => {
  const name = metricName.toLowerCase()
  if (name.includes('your-metric')) return YourIcon
  // ... existing logic
}
```

## Troubleshooting

### "Please configure GEMINI_API_KEY" Error

**Solution**:
1. Verify `.env` file in `backend/` directory
2. Check `GEMINI_API_KEY=your-key` is set
3. Restart backend server
4. Verify API key is valid at [Google AI Studio](https://makersuite.google.com/app/apikey)

### No Metrics Extracted

**Possible Causes**:
1. Image quality too low
2. Text not clearly visible
3. Non-standard report format
4. AI couldn't identify metrics

**Solutions**:
- Upload higher quality image
- Ensure report contains numeric values
- Try different lighting/scan
- Check backend logs for errors

### Incorrect Metric Values

**Causes**:
- OCR misread values
- Unusual report format
- AI misinterpreted data

**Solutions**:
- Verify source report
- Try uploading again
- Use clearer image
- Always verify with original report

### Upload Fails

**Solutions**:
1. Check file size < 10MB
2. Verify file format (JPG, PNG, PDF only)
3. Check internet connection
4. Verify backend is running
5. Check CORS settings

### Slow Analysis

**Causes**:
- Large file size
- API rate limits
- Network latency

**Solutions**:
- Compress images before upload
- Upgrade to paid Gemini tier
- Use faster model (gemini-2.5-flash)

## Security & Privacy

### Data Handling

1. **File Storage**:
   - Files saved temporarily in `backend/uploads/`
   - Named with user ID + filename
   - Clean up old files regularly

2. **API Security**:
   - All endpoints require authentication
   - JWT tokens for user verification
   - CORS configured for frontend only

3. **Privacy**:
   - Health data processed through Google Gemini API
   - Review [Google AI Privacy Policy](https://policies.google.com/privacy)
   - Consider on-premise solutions for PHI/HIPAA compliance

### Production Recommendations

1. **Encryption**:
   - Use HTTPS for all connections
   - Encrypt files at rest
   - Encrypt data in transit

2. **Compliance**:
   - For HIPAA: Use Business Associate Agreement (BAA) with Google
   - For GDPR: Implement data retention policies
   - Log all access for audit trails

3. **File Management**:
   ```python
   # Implement automatic cleanup
   # backend/app/services/file_cleanup.py
   import os
   import time

   def cleanup_old_files(upload_dir, max_age_hours=24):
       now = time.time()
       for filename in os.listdir(upload_dir):
           filepath = os.path.join(upload_dir, filename)
           if os.path.getmtime(filepath) < now - (max_age_hours * 3600):
               os.remove(filepath)
   ```

## Cost Management

### Gemini API Pricing

**Free Tier**:
- 60 requests per minute
- 1500 requests per day
- Suitable for development/testing

**Paid Tier**:
- Higher rate limits
- Better performance
- Production use

### Optimization Tips

1. **Image Compression**:
   ```python
   from PIL import Image

   def compress_image(image, max_size=(1920, 1080), quality=85):
       image.thumbnail(max_size, Image.Resampling.LANCZOS)
       return image
   ```

2. **Caching**:
   - Cache common report analyses
   - Store in MongoDB with TTL
   - Reduce repeat API calls

3. **Rate Limiting**:
   - Implement per-user limits
   - Queue large batches
   - Display wait times

## Advanced Features (Future Enhancements)

Potential additions:
- **Trend Analysis**: Track metrics over time
- **Multi-Report Comparison**: Compare multiple reports
- **Export Options**: PDF summary, email reports
- **Voice Input**: Describe symptoms verbally
- **Multi-Language**: Support various languages
- **Doctor Portal**: Specialized view for physicians
- **Integration**: EHR system integration
- **Wearable Data**: Import from fitness trackers
- **AI Chat**: Conversational follow-up questions

## Testing

### Sample Test Reports

Create test reports with various metrics:

1. **Normal Report**: All metrics in healthy range
2. **Warning Report**: Some elevated values
3. **Critical Report**: Values requiring attention
4. **Complex Report**: Multiple test types
5. **Poor Quality**: Test OCR capabilities

### Manual Testing Checklist

- [ ] Upload JPG image
- [ ] Upload PNG image
- [ ] Upload PDF document
- [ ] Test file size limit (>10MB)
- [ ] Test invalid file types
- [ ] Verify all metrics extracted
- [ ] Check status colors correct
- [ ] Verify recommendations shown
- [ ] Test error handling
- [ ] Test without API key
- [ ] Test with invalid API key
- [ ] Test network timeout
- [ ] Test concurrent uploads

## Support & Resources

- **Gemini API Docs**: https://ai.google.dev/docs
- **Gemini Models**: https://ai.google.dev/models/gemini
- **FastAPI Docs**: https://fastapi.tiangolo.com/
- **React Docs**: https://react.dev/
- **Pillow Docs**: https://pillow.readthedocs.io/

## Contributing

To contribute enhancements:
1. Test thoroughly with various report types
2. Document new features
3. Update this guide
4. Submit with test cases

## License & Disclaimer

**Medical Disclaimer**: This AI tool is for informational and educational purposes only. It does not provide medical advice, diagnosis, or treatment. Always consult qualified healthcare professionals for medical decisions.

**Data Privacy**: By using this service, you acknowledge that health report data is processed by Google's Gemini AI. Review applicable privacy policies and ensure compliance with healthcare regulations in your jurisdiction.
