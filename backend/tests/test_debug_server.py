"""
Test the debug FastAPI server
"""
import requests
import json

url = "http://localhost:8001/test-login"
payload = {
    "email": "patient@test.com",
    "password": "password123",
    "role": "patient"
}

print(f"Testing POST to {url}")
print(f"Payload: {json.dumps(payload, indent=2)}")

try:
    response = requests.post(url, json=payload)
    print(f"\nStatus Code: {response.status_code}")
    print(f"\nResponse Body:")
    print(response.text)

    if response.status_code == 200:
        print("\n[SUCCESS] Login successful!")
        data = response.json()
        print(f"Token: {data.get('access_token', 'N/A')[:30]}...")
        print(f"User: {data.get('user', 'N/A')}")
    else:
        print(f"\n[ERROR] Login failed with status {response.status_code}")

except Exception as e:
    print(f"\n[ERROR] Request failed: {e}")
