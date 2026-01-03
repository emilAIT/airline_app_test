from app.services.seat_generator import generate_seat_map, calculate_airplane_layout, SeatInfo

def test():
    print("Testing generator...")
    total_seats = 180
    layout = calculate_airplane_layout(total_seats)
    print(f"Layout: {layout}")
    
    seats = generate_seat_map(total_seats=total_seats, extra_legroom_rows=layout["extra_legroom_rows"])
    print(f"Generated {len(seats)} seats.")
    print(f"Sample: {seats[0] if seats else 'None'}")

if __name__ == "__main__":
    test()
