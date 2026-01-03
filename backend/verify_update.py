import requests
import json

BASE_URL = "http://localhost:8000"

def login_staff():
    # Login as staff (from seed data)
    resp = requests.post(f"{BASE_URL}/auth/token", data={
        "username": "staff@airline.com",
        "password": "staff123"
    })
    return resp.json()["access_token"]

def verify_update():
    token = login_staff()
    headers = {"Authorization": f"Bearer {token}"}
    
    # 1. Get Airplane 1
    print("Getting Airplane 1...")
    resp = requests.get(f"{BASE_URL}/staff/airplanes/1", headers=headers)
    if resp.status_code != 200:
        print(f"Failed to get airplane: {resp.status_code} {resp.text}")
        return
    
    airplane = resp.json()
    print(f"Current State: {json.dumps(airplane, indent=2)}")
    current_capacity = airplane["total_seats"]
    
    # 2. Try to update Model ONLY (Capacity same implicitly or explicitly?)
    # Scenario A: Send same capacity
    print("\nScenario A: Updating with SAME capacity...")
    payload_a = {
        "model": "Updated Boeing 737",
        "registration": airplane["registration"],
        "total_seats": current_capacity
    }
    resp_a = requests.patch(f"{BASE_URL}/staff/airplanes/1", headers=headers, json=payload_a)
    print(f"Status: {resp_a.status_code}")
    print(f"Response: {resp_a.text}")

    # Scenario B: Try to change capacity (Should fail 400)
    print("\nScenario B: Updating with DIFFERENT capacity (Should Fail)...")
    payload_b = {
        "total_seats": current_capacity + 6
    }
    resp_b = requests.patch(f"{BASE_URL}/staff/airplanes/1", headers=headers, json=payload_b)
    print(f"Status: {resp_b.status_code}")
    print(f"Response: {resp_b.text}")

if __name__ == "__main__":
    verify_update()
