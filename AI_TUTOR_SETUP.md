# AI Health Tutor Setup Guide

This guide explains how to set up and use the AI Health Tutor feature powered by Google Gemini 2.5 Flash.

## Features

The AI Health Tutor provides:
- **Medical Term Search**: Search for any medical term or health concept
- **AI-Powered Explanations**: Get clear, patient-friendly explanations using Gemini 2.5 Flash
- **Practical Examples**: Learn how terms are used in medical contexts
- **Popular Terms**: Quick access to commonly searched medical terms
- **Real-time Search**: Instant AI-powered responses

## Prerequisites

1. **Google Gemini API Key**: You need a Gemini API key from Google AI Studio
2. **Python 3.8+**: Backend requires Python
3. **Node.js 18+**: Frontend requires Node.js

## Setup Instructions

### Step 1: Get Your Gemini API Key

1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Create API Key" or "Get API Key"
4. Copy your API key

### Step 2: Configure Backend

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Create a `.env` file (or update existing one):
   ```bash
   cp .env.example .env
   ```

3. Edit `.env` file and add your Gemini API key:
   ```env
   GEMINI_API_KEY=your-actual-gemini-api-key-here
   ```

4. Install the required dependencies:
   ```bash
   # On Windows with venv
   .\venv\Scripts\pip.exe install -r requirements.txt

   # On Mac/Linux
   pip install -r requirements.txt
   ```

   This will install `google-generativeai==0.8.3` along with other dependencies.

### Step 3: Start the Backend Server

```bash
# On Windows with venv
.\venv\Scripts\python.exe run.py

# On Mac/Linux
python run.py
```

The backend will start on `http://localhost:8000`

### Step 4: Start the Frontend

1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```

2. Install dependencies (if not already done):
   ```bash
   npm install
   ```

3. Start the development server:
   ```bash
   npm run dev
   ```

The frontend will start on `http://localhost:5173`

## Using the AI Health Tutor

### Web Interface

1. **Open the Application**: Navigate to `http://localhost:5173`

2. **Login**: Sign in with your credentials (or create an account)

3. **Find the AI Tutor**: The AI Health Tutor appears on the home page

4. **Search for Terms**:
   - Type any medical term in the search box (e.g., "hypertension", "diabetes", "MRI")
   - Press Enter or click "Search"
   - Wait for AI-powered results from Gemini 2.0 Flash

5. **Quick Search**: Click on any popular term button for instant search

### API Endpoints

#### Search Medical Term
```http
POST /api/ai/tutor/search
Authorization: Bearer <your-token>
Content-Type: application/json

{
  "query": "hypertension"
}
```

**Response:**
```json
{
  "term": "hypertension",
  "definition": "Hypertension, also known as high blood pressure, is a condition where the force of blood against artery walls is consistently too high...",
  "examples": [
    "Common usage: 'The patient was diagnosed with hypertension during routine screening'",
    "Related terms: cardiovascular disease, systolic pressure, diastolic pressure",
    "When to seek help: If you experience persistent headaches, shortness of breath, or nosebleeds"
  ]
}
```

#### Get Popular Terms
```http
GET /api/ai/tutor/popular-terms
Authorization: Bearer <your-token>
```

**Response:**
```json
{
  "terms": [
    "Hypertension",
    "Diabetes",
    "Cholesterol",
    "BMI",
    "Cardiovascular",
    "Inflammation"
  ]
}
```

## AI Service Architecture

### Backend (`backend/app/services/ai_service.py`)

The AI service uses Google's Gemini 2.5 Flash model:

```python
# Initialize Gemini 2.5 Flash model
model = genai.GenerativeModel('gemini-2.5-flash')

# Create prompt for medical term explanation
prompt = """You are a medical tutor AI assistant. Provide a comprehensive
yet easy-to-understand explanation of the medical term or health concept..."""

# Generate response
response = model.generate_content(prompt)
```

### Prompt Engineering

The system uses a structured prompt that requests:
- Clear, patient-friendly definitions (2-3 sentences)
- Practical examples showing medical context
- Related terms and concepts
- When to seek medical help

### Error Handling

The service includes robust error handling:
- **No API Key**: Returns helpful fallback message
- **API Errors**: Catches exceptions and provides user-friendly error messages
- **Invalid Responses**: Parses response intelligently with fallback formatting

## Customization

### Change the AI Model

Edit `backend/app/services/ai_service.py`:

```python
# Current model
model = genai.GenerativeModel('gemini-2.5-flash')

# Alternative models
model = genai.GenerativeModel('gemini-1.5-flash')  # Older but stable
model = genai.GenerativeModel('gemini-1.5-pro')    # More powerful
model = genai.GenerativeModel('gemini-2.0-flash-exp')  # Experimental 2.0
```

### Customize Popular Terms

Edit `backend/app/services/ai_service.py`:

```python
@staticmethod
async def get_popular_terms() -> List[str]:
    return [
        "Your Custom Term 1",
        "Your Custom Term 2",
        # Add more terms...
    ]
```

### Modify the Prompt

Edit the prompt in `backend/app/services/ai_service.py` to change how the AI responds:

```python
prompt = f"""Your custom prompt here...

Structure your response to include:
- Custom section 1
- Custom section 2
...
"""
```

## Troubleshooting

### "Please configure GEMINI_API_KEY" Error

**Problem**: API key not configured
**Solution**:
1. Check `.env` file exists in `backend/` directory
2. Verify `GEMINI_API_KEY=your-key-here` is set
3. Restart the backend server

### "Failed to search" Error

**Problem**: API request failed
**Solutions**:
1. Verify API key is valid
2. Check internet connection
3. Verify Gemini API quota (free tier has limits)
4. Check backend logs for detailed error messages

### Empty or Malformed Responses

**Problem**: AI response doesn't follow expected format
**Solution**: The service has fallback parsing that handles this automatically, but you can modify the prompt to be more specific

### CORS Errors

**Problem**: Frontend can't connect to backend
**Solution**: Verify backend is running on `http://localhost:8000` and CORS is configured in `backend/app/main.py`

## Cost Considerations

### Gemini API Pricing

- **Free Tier**: 60 requests per minute
- **Paid Tier**: Check [Google AI Pricing](https://ai.google.dev/pricing)

### Optimization Tips

1. **Cache Results**: Consider caching common terms in MongoDB
2. **Rate Limiting**: Implement rate limiting for API requests
3. **Model Selection**: Use `gemini-2.5-flash` (faster, cheaper) instead of `gemini-1.5-pro`

## Security Best Practices

1. **Never commit** `.env` file to version control
2. **Rotate** API keys regularly
3. **Set environment variables** in production (don't use `.env` files)
4. **Implement rate limiting** to prevent abuse
5. **Validate user input** before sending to AI
6. **Monitor API usage** to detect anomalies

## Production Deployment

When deploying to production:

1. **Set Environment Variables**:
   ```bash
   export GEMINI_API_KEY=your-production-key
   ```

2. **Use Environment-Specific Config**:
   - AWS: Use Parameter Store or Secrets Manager
   - Docker: Use secrets or environment variables
   - Kubernetes: Use ConfigMaps and Secrets

3. **Enable Monitoring**:
   - Log all API requests
   - Track response times
   - Monitor API quota usage
   - Set up alerts for errors

## Future Enhancements

Potential improvements:
- **Chat History**: Store and display previous searches
- **Bookmarks**: Save favorite terms
- **Voice Input**: Search using voice commands
- **Multi-language**: Support multiple languages
- **Related Terms**: Show related medical concepts
- **Images/Diagrams**: Include visual explanations
- **Video Content**: Link to educational videos

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review backend logs: Check console where `run.py` is running
3. Review browser console for frontend errors
4. Check Gemini API status: [Google Cloud Status](https://status.cloud.google.com/)

## Related Documentation

- [Google Gemini API Documentation](https://ai.google.dev/docs)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [React Documentation](https://react.dev/)
