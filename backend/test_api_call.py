"""Test API call with detailed error handling"""
import requests
import json

API_BASE_URL = "http://localhost:8000"
SIGNUP_ENDPOINT = f"{API_BASE_URL}/api/auth/signup"

# Test user data
user_data = {
    "name": "API Test User",
    "email": "apitest@example.com",
    "password": "testpass123"
}

print(f"Testing signup API...")
print(f"Endpoint: {SIGNUP_ENDPOINT}")
print(f"Data: {json.dumps(user_data, indent=2)}")
print("-" * 60)

try:
    response = requests.post(
        SIGNUP_ENDPOINT,
        json=user_data,
        headers={"Content-Type": "application/json"},
        timeout=10
    )

    print(f"Status Code: {response.status_code}")
    print(f"Headers: {dict(response.headers)}")
    print(f"Response Text: {response.text}")

    if response.status_code == 201:
        data = response.json()
        print("\nSignup Successful!")
        print(f"Response: {json.dumps(data, indent=2)}")
    else:
        print(f"\nSignup Failed!")
        try:
            error_data = response.json()
            print(f"Error JSON: {json.dumps(error_data, indent=2)}")
        except:
            print(f"Error Text: {response.text}")

except requests.exceptions.Timeout:
    print("Request timed out!")
except requests.exceptions.ConnectionError:
    print("Connection Error: Make sure the backend server is running!")
except Exception as e:
    print(f"Unexpected Error: {type(e).__name__}: {e}")
    import traceback
    traceback.print_exc()
