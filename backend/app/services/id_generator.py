"""
Utility functions for generating unique identifiers.
"""
import random
import string


def generate_pnr() -> str:
    """
    Generate random 6-character PNR (Passenger Name Record).
    
    Format: uppercase alphanumeric (A-Z, 0-9)
    Example: "A1B2C3"
    """
    chars = string.ascii_uppercase + string.digits
    return ''.join(random.choices(chars, k=6))


def generate_ticket_number() -> str:
    """
    Generate airline-style ticket number.
    
    Format: "784" + 10 random digits
    Example: "7841234567890"
    
    "784" is airline code prefix (fictional for ZaKu).
    """
    digits = ''.join(random.choices(string.digits, k=10))
    return f"784{digits}"
