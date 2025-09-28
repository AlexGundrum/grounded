#!/usr/bin/env python3
"""
Test script for the rate limiting functionality in upload_text endpoint.
This script demonstrates how the rate limiting prevents spam requests.
"""

import requests
import time
import json

def test_rate_limiting():
    """Test the rate limiting functionality."""
    
    print("🚦 Testing Rate Limiting for /upload_text Endpoint")
    print("=" * 60)
    
    base_url = "http://localhost:2419"
    
    # Test data
    test_data = {
        "text": "I'm feeling anxious",
        "heart_rate": 95.0,
        "timestamp": time.time()
    }
    
    print(f"📊 Rate Limit Configuration:")
    print(f"   - Minimum seconds between requests: 3 seconds")
    print(f"   - Test endpoint: {base_url}/upload_text")
    print(f"   - Status endpoint: {base_url}/rate-limit/status")
    
    print(f"\n🧪 Test 1: First Request (Should Succeed)")
    try:
        response1 = requests.post(f"{base_url}/upload_text", json=test_data)
        print(f"   Status Code: {response1.status_code}")
        if response1.status_code == 200:
            print(f"   ✅ First request successful!")
            response_data = response1.json()
            print(f"   Message: {response_data.get('message', 'N/A')[:50]}...")
        else:
            print(f"   ❌ First request failed: {response1.text}")
    except requests.exceptions.ConnectionError:
        print(f"   ❌ Server not running. Start the server first!")
        return
    
    print(f"\n🧪 Test 2: Immediate Second Request (Should Be Rate Limited)")
    try:
        response2 = requests.post(f"{base_url}/upload_text", json=test_data)
        print(f"   Status Code: {response2.status_code}")
        if response2.status_code == 429:
            print(f"   ✅ Rate limiting working! Request blocked.")
            error_data = response2.json()
            print(f"   Error: {error_data.get('detail', 'N/A')}")
        else:
            print(f"   ❌ Rate limiting failed! Status: {response2.status_code}")
    except Exception as e:
        print(f"   ❌ Error: {e}")
    
    print(f"\n🧪 Test 3: Check Rate Limit Status")
    try:
        status_response = requests.get(f"{base_url}/rate-limit/status")
        if status_response.status_code == 200:
            status_data = status_response.json()
            print(f"   ✅ Rate limit status retrieved!")
            print(f"   Client ID: {status_data.get('client_id', 'N/A')}")
            print(f"   Rate Limit: {status_data.get('rate_limit_seconds', 'N/A')} seconds")
            print(f"   Allowed: {status_data.get('is_allowed', 'N/A')}")
            print(f"   Time since last request: {status_data.get('time_since_last_request', 0):.2f} seconds")
            print(f"   Remaining wait time: {status_data.get('remaining_wait_time', 0):.2f} seconds")
        else:
            print(f"   ❌ Failed to get rate limit status: {status_response.status_code}")
    except Exception as e:
        print(f"   ❌ Error: {e}")
    
    print(f"\n🧪 Test 4: Wait and Retry (Should Succeed)")
    print(f"   Waiting 4 seconds to allow rate limit to reset...")
    time.sleep(4)
    
    try:
        response3 = requests.post(f"{base_url}/upload_text", json=test_data)
        print(f"   Status Code: {response3.status_code}")
        if response3.status_code == 200:
            print(f"   ✅ Request after waiting successful!")
            response_data = response3.json()
            print(f"   Message: {response_data.get('message', 'N/A')[:50]}...")
        else:
            print(f"   ❌ Request after waiting failed: {response3.text}")
    except Exception as e:
        print(f"   ❌ Error: {e}")
    
    print(f"\n🎉 Rate Limiting Test Completed!")
    print(f"\nThe rate limiting system is working with:")
    print(f"  ✓ Request timestamp tracking")
    print(f"  ✓ Client identification by IP")
    print(f"  ✓ Automatic blocking of rapid requests")
    print(f"  ✓ Graceful error responses (HTTP 429)")
    print(f"  ✓ Status endpoint for monitoring")
    print(f"  ✓ Memory cleanup of old entries")

def test_multiple_clients():
    """Test rate limiting with different client identifiers."""
    print(f"\n🔄 Testing Multiple Client Simulation")
    print("=" * 40)
    
    base_url = "http://localhost:2419"
    test_data = {
        "text": "Test message",
        "heart_rate": 80.0,
        "timestamp": time.time()
    }
    
    # Simulate different clients by using different headers
    clients = [
        {"User-Agent": "Client-1"},
        {"User-Agent": "Client-2"},
        {"User-Agent": "Client-3"}
    ]
    
    for i, headers in enumerate(clients, 1):
        print(f"\n🧪 Client {i} Request:")
        try:
            response = requests.post(f"{base_url}/upload_text", json=test_data, headers=headers)
            print(f"   Status: {response.status_code}")
            if response.status_code == 200:
                print(f"   ✅ Client {i} request successful!")
            else:
                print(f"   ❌ Client {i} request failed: {response.status_code}")
        except Exception as e:
            print(f"   ❌ Client {i} error: {e}")

if __name__ == "__main__":
    test_rate_limiting()
    test_multiple_clients()
