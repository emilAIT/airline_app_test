import requests
from datetime import datetime, timedelta

BASE_URL = "http://localhost:8000/api/v1"

def debug_search():
    print("🕵️ Debugging Search...")
    
    # 1. Get Airports to get real IDs
    print("1. Fetching Airports...")
    try:
        resp = requests.get(f"{BASE_URL}/airports")
        airports = resp.json()
        print(f"   Got {len(airports)} airports")
        
        fru = next((a for a in airports if a['code'] == 'FRU'), None)
        oss = next((a for a in airports if a['code'] == 'OSS'), None)
        
        if not fru or not oss:
            print("ERROR: Could not find FRU or OSS ids")
            return
            
        print(f"   FRU ID: {fru['id']}, OSS ID: {oss['id']}")
        
        # 2. Search for flights FRU -> OSS for next 5 days
        for i in range(5):
            date_obj = datetime.now() + timedelta(days=i)
            date_str = date_obj.strftime("%Y-%m-%d")
            
            print(f"\n2. Searching FRU->OSS for {date_str}...")
            url = f"{BASE_URL}/flights"
            params = {
                "origin_id": fru['id'],
                "destination_id": oss['id'],
                "departure_date": date_str
            }
            
            resp = requests.get(url, params=params)
            if resp.status_code == 200:
                results = resp.json()
                print(f"   CODE: {resp.status_code}")
                print(f"   FOUND: {len(results)} flights")
                for f in results:
                    print(f"     - {f['flight_number']} {f['departure_time']} (Status: {f['status']})")
            else:
                print(f"   ERROR: {resp.status_code} {resp.text}")

    except Exception as e:
        print(f"ERROR: Exception: {e}")

if __name__ == "__main__":
    debug_search()
