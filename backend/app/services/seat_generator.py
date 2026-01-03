"""
Dynamic seat map generator.

Replaces static SeatTemplate tables with algorithmic generation based on airplane capacity.
"""
from typing import List, Dict, Literal
from pydantic import BaseModel


# Standard airline seat layout constants
SEATS_PER_ROW = 6  # Standard: A, B, C | D, E, F (3-3 configuration)
SEAT_LETTERS = ['A', 'B', 'C', 'D', 'E', 'F']
EXTRA_LEGROOM_SEAT_LETTERS = ['A', 'B', 'C', 'D', 'E', 'F']


SeatClass = Literal["STANDARD", "EXTRA_LEGROOM"]


class SeatInfo(BaseModel):
    """Individual seat information."""
    seat_number: str  # e.g., "12A"
    seat_class: SeatClass
    row: int
    letter: str


def generate_seat_map(total_seats: int, extra_legroom_rows: int = 0) -> List[SeatInfo]:
    """
    Generate seat map dynamically based on airplane capacity.
    
    Algorithm:
        1. Extra Legroom: Rows 1-{extra_legroom_rows}
        2. Standard: Remaining seats
    
    Args:
        total_seats: Total airplane capacity
        extra_legroom_rows: Number of rows allocated to extra legroom (default: 0)
    
    Returns:
        List of SeatInfo objects representing the complete seat map
    """
    seats: List[SeatInfo] = []
    current_row = 1
    remaining_seats = total_seats
    
    # Generate Extra Legroom seats (if any)
    if extra_legroom_rows > 0:
        for row in range(current_row, current_row + extra_legroom_rows):
            for letter in EXTRA_LEGROOM_SEAT_LETTERS:
                if remaining_seats <= 0:
                    break
                seats.append(SeatInfo(
                    seat_number=f"{row}{letter}",
                    seat_class="EXTRA_LEGROOM",
                    row=row,
                    letter=letter
                ))
                remaining_seats -= 1
        current_row += extra_legroom_rows
    
    # Generate Standard seats (remaining capacity)
    while remaining_seats > 0:
        for letter in SEAT_LETTERS:
            if remaining_seats <= 0:
                break
            seats.append(SeatInfo(
                seat_number=f"{current_row}{letter}",
                seat_class="STANDARD",
                row=current_row,
                letter=letter
            ))
            remaining_seats -= 1
        current_row += 1
    
    return seats


def calculate_airplane_layout(total_seats: int) -> Dict[str, int]:
    """
    Calculate optimal seat class distribution for an airplane.
    
    Standard convention for this LCC-style app:
        - 10-15% Extra Legroom (Front of cabin)
        - Rest Standard
    
    Returns:
        Dict with keys: extra_legroom_rows
    """
    # Allocate approx 15% to extra legroom
    extra_seats = int(total_seats * 0.15)
    # Ensure full rows
    extra_rows = (extra_seats + SEATS_PER_ROW - 1) // SEATS_PER_ROW
    
    return {
        "extra_legroom_rows": extra_rows
    }
