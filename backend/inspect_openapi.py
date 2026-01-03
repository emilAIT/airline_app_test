import json


def main() -> None:
    with open('backend/_openapi.json', 'r', encoding='utf-8') as f:
        openapi = json.load(f)

    schemas = (openapi.get('components') or {}).get('schemas') or {}

    print('has_/api/v1/bookings:', '/api/v1/bookings' in (openapi.get('paths') or {}))

    passenger_info = schemas.get('PassengerInfo') or {}
    props = passenger_info.get('properties') or {}
    print('PassengerInfo properties:', sorted(props.keys()))

    booking_response = schemas.get('BookingResponse') or {}
    br_props = booking_response.get('properties') or {}
    print('BookingResponse has booking_id:', 'booking_id' in br_props)
    print('BookingResponse has passengers:', 'passengers' in br_props)


if __name__ == '__main__':
    main()
