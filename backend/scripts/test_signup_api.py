"""
Test script for user signup API endpoint
Tests user registration and MongoDB storage
"""

import requests
import json
from datetime import datetime
import sys
import io

# Set stdout encoding to UTF-8 to handle Unicode characters
if sys.stdout.encoding != 'utf-8':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# Configuration
API_BASE_URL = "http://localhost:8000"
SIGNUP_ENDPOINT = f"{API_BASE_URL}/api/auth/signup"
LOGIN_ENDPOINT = f"{API_BASE_URL}/api/auth/login"

# Test user data
test_users = [
    {
        "name": "Alice Johnson",
        "email": f"alice.test+{datetime.now().timestamp()}@example.com",
        "password": "securepass123"
    },
    {
        "name": "Bob Smith",
        "email": f"bob.test+{datetime.now().timestamp()}@example.com",
        "password": "password456"
    },
    {
        "name": "Carol Williams",
        "email": f"carol.test+{datetime.now().timestamp()}@example.com",
        "password": "mypassword789"
    }
]


def print_separator():
    print("\n" + "="*80 + "\n")


def test_signup(user_data):
    """Test user signup endpoint"""
    print(f"🧪 Testing Signup for: {user_data['name']} ({user_data['email']})")
    print("-" * 80)

    try:
        response = requests.post(
            SIGNUP_ENDPOINT,
            json=user_data,
            headers={"Content-Type": "application/json"}
        )

        print(f"Status Code: {response.status_code}")

        if response.status_code == 201:
            data = response.json()
            print("✅ Signup Successful!")
            print(f"\nResponse Data:")
            print(f"  • Access Token: {data['access_token'][:50]}...")
            print(f"  • Token Type: {data['token_type']}")
            print(f"\nUser Info:")
            print(f"  • User ID: {data['user']['id']}")
            print(f"  • Name: {data['user']['name']}")
            print(f"  • Email: {data['user']['email']}")
            print(f"  • Role: {data['user']['role']}")

            return {
                "success": True,
                "user": data['user'],
                "token": data['access_token']
            }
        else:
            print(f"❌ Signup Failed!")
            print(f"Error: {response.text}")
            return {"success": False, "error": response.text}

    except requests.exceptions.ConnectionError:
        print("❌ Connection Error: Make sure the backend server is running!")
        print("   Run: cd backend && python -m uvicorn app.main:app --reload")
        return {"success": False, "error": "Connection failed"}
    except Exception as e:
        print(f"❌ Unexpected Error: {str(e)}")
        return {"success": False, "error": str(e)}


def test_duplicate_signup(user_data):
    """Test that duplicate email signup fails"""
    print(f"🧪 Testing Duplicate Signup Prevention: {user_data['email']}")
    print("-" * 80)

    try:
        response = requests.post(
            SIGNUP_ENDPOINT,
            json=user_data,
            headers={"Content-Type": "application/json"}
        )

        print(f"Status Code: {response.status_code}")

        if response.status_code == 400:
            print("✅ Duplicate Prevention Working!")
            print(f"Expected error received: {response.json()['detail']}")
            return {"success": True}
        else:
            print("❌ Duplicate signup was allowed (should have failed!)")
            return {"success": False}

    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return {"success": False, "error": str(e)}


def test_login(email, password):
    """Test login with newly created account"""
    print(f"🧪 Testing Login for: {email}")
    print("-" * 80)

    try:
        response = requests.post(
            LOGIN_ENDPOINT,
            json={
                "email": email,
                "password": password,
                "role": "patient"
            },
            headers={"Content-Type": "application/json"}
        )

        print(f"Status Code: {response.status_code}")

        if response.status_code == 200:
            data = response.json()
            print("✅ Login Successful!")
            print(f"  • User: {data['user']['name']}")
            print(f"  • Email: {data['user']['email']}")
            print(f"  • Role: {data['user']['role']}")
            return {"success": True}
        else:
            print(f"❌ Login Failed!")
            print(f"Error: {response.text}")
            return {"success": False}

    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return {"success": False, "error": str(e)}


def verify_mongodb_storage():
    """Verify that data is stored in MongoDB"""
    print("🔍 Verifying MongoDB Storage")
    print("-" * 80)
    print("To verify data in MongoDB, run:")
    print("\n  mongosh")
    print("  use careflowai")
    print("  db.users.find().pretty()")
    print("\nOr check with Python:")
    print("  python -c 'from motor.motor_asyncio import AsyncIOMotorClient; import asyncio; asyncio.run(AsyncIOMotorClient(\"mongodb://localhost:27017\").careflowai.users.find().to_list(None))'\n")


def run_all_tests():
    """Run all tests"""
    print("\n")
    print("=" * 80)
    print(" " * 20 + "USER SIGNUP API TEST SUITE")
    print("=" * 80)
    print_separator()

    results = {
        "total": 0,
        "passed": 0,
        "failed": 0
    }

    created_users = []

    # Test 1: Signup new users
    print("📋 TEST SUITE 1: User Signup\n")
    for i, user in enumerate(test_users, 1):
        print(f"Test {i}/{len(test_users)}")
        result = test_signup(user)
        results["total"] += 1

        if result["success"]:
            results["passed"] += 1
            created_users.append(user)
        else:
            results["failed"] += 1

        print_separator()

    # Test 2: Duplicate signup prevention
    if created_users:
        print("📋 TEST SUITE 2: Duplicate Signup Prevention\n")
        result = test_duplicate_signup(created_users[0])
        results["total"] += 1

        if result["success"]:
            results["passed"] += 1
        else:
            results["failed"] += 1

        print_separator()

    # Test 3: Login with created accounts
    if created_users:
        print("📋 TEST SUITE 3: Login with New Accounts\n")
        for i, user in enumerate(created_users, 1):
            print(f"Test {i}/{len(created_users)}")
            result = test_login(user["email"], user["password"])
            results["total"] += 1

            if result["success"]:
                results["passed"] += 1
            else:
                results["failed"] += 1

            print_separator()

    # MongoDB verification instructions
    verify_mongodb_storage()
    print_separator()

    # Summary
    print("=" * 80)
    print(" " * 30 + "TEST SUMMARY")
    print("=" * 80)
    print(f"\n  Total Tests: {results['total']}")
    print(f"  ✅ Passed: {results['passed']}")
    print(f"  ❌ Failed: {results['failed']}")
    print(f"  Success Rate: {(results['passed']/results['total']*100) if results['total'] > 0 else 0:.1f}%\n")

    if results["failed"] == 0:
        print("🎉 All tests passed! User signup is working correctly.\n")
    else:
        print("⚠️  Some tests failed. Check the output above for details.\n")

    return results["failed"] == 0


if __name__ == "__main__":
    success = run_all_tests()
    sys.exit(0 if success else 1)
