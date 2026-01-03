import requests


BASE_URL = "http://localhost:8000/api/v1"


def check_api() -> int:
    print("Checking API (exam contract)...")

    # 1) Airports exist
    resp_airports = requests.get(f"{BASE_URL}/airports")
    if resp_airports.status_code != 200:
        print(f"ERROR: GET /airports failed: {resp_airports.status_code} {resp_airports.text}")
        return 1
    airports = resp_airports.json()
    print(f"OK: GET /airports returned {len(airports)} airports")
    needed = {"ALA", "NQZ", "DXB"}
    got = {a.get("code") for a in airports}
    if not needed.issubset(got):
        print(f"ERROR: Missing required airports. Need={needed}, got={got}")
        return 1

    # 2) Flights list supports query params and returns required fields
    resp_flights = requests.get(f"{BASE_URL}/flights")
    if resp_flights.status_code != 200:
        print(f"ERROR: GET /flights failed: {resp_flights.status_code} {resp_flights.text}")
        return 1
    flights = resp_flights.json()
    print(f"OK: GET /flights returned {len(flights)} flights")
    if not flights:
        print("ERROR: Expected seeded flights, got empty list")
        return 1

    first = flights[0]
    required_flight_keys = {"id", "flight_number", "origin_id", "destination_id", "departure_time", "arrival_time", "price", "status"}
    missing = required_flight_keys.difference(first.keys())
    if missing:
        print(f"ERROR: Flight response missing keys: {missing}. Got keys={set(first.keys())}")
        return 1

    fid = first["id"]
    origin_id = first["origin_id"]
    destination_id = first["destination_id"]
    date_str = first["departure_time"][0:10]

    resp_filtered = requests.get(
        f"{BASE_URL}/flights",
        params={"origin_id": origin_id, "destination_id": destination_id, "date": date_str},
    )
    if resp_filtered.status_code != 200:
        print(f"ERROR: GET /flights with filters failed: {resp_filtered.status_code} {resp_filtered.text}")
        return 1
    filtered = resp_filtered.json()
    print(f"OK: GET /flights?origin_id=...&destination_id=...&date=... returned {len(filtered)} flights")

    # 3) Seats endpoint returns full seat map
    resp_seats = requests.get(f"{BASE_URL}/flights/{fid}/seats")
    if resp_seats.status_code != 200:
        print(f"ERROR: GET /flights/{fid}/seats failed: {resp_seats.status_code} {resp_seats.text}")
        return 1
    seats = resp_seats.json()
    print(f"OK: GET /flights/{fid}/seats returned {len(seats)} seats")
    if len(seats) != 120:
        print("ERROR: Expected 120 seats (20 rows x 6 letters)")
        return 1

    required_seat_keys = {"id", "flight_id", "code", "seat_class", "is_occupied", "price_markup"}
    missing_seat = required_seat_keys.difference(seats[0].keys())
    if missing_seat:
        print(f"ERROR: Seat response missing keys: {missing_seat}. Got keys={set(seats[0].keys())}")
        return 1

    classes = {s["seat_class"] for s in seats}
    if not {"STANDARD", "EXTRA_LEGROOM"}.issubset(classes):
        print(f"ERROR: Expected both seat classes, got: {classes}")
        return 1

    occupied = sum(1 for s in seats if s["is_occupied"])
    if occupied != 5:
        print(f"ERROR: Expected 5 occupied seats, got {occupied}")
        return 1

    print("API check PASSED")
    return 0


if __name__ == "__main__":
    raise SystemExit(check_api())
