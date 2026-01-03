"""
Mock in-memory storage for development.
Stores all data in memory without database.
"""
from typing import Dict, List, Optional
from datetime import datetime
from app.models.user import User, UserRole
from app.core.security import get_password_hash, verify_password


class Booking:
    """Mock booking model"""
    def __init__(
        self, 
        id: int, 
        user_id: int, 
        flight_id: int, 
        seat_numbers: List[str],
        payment_method: Optional[str] = None,
        passenger_info: Optional[List[dict]] = None
    ):
        self.id = id
        self.user_id = user_id
        self.flight_id = flight_id
        self.seat_numbers = seat_numbers  # Список забронированных мест
        self.passenger_count = len(seat_numbers)
        self.payment_method = payment_method  # "CARD", "APPLE_PAY", "GOOGLE_PAY"
        self.passenger_info = passenger_info or []  # List of passenger details
        self.created_at = datetime.utcnow()


class MockStorage:
    """In-memory storage for all application data"""
    
    def __init__(self):
        self.users: Dict[int, User] = {}
        self.users_by_email: Dict[str, User] = {}
        self.next_user_id = 1
        self.bookings: Dict[int, Booking] = {}
        self.next_booking_id = 1
        
        # Initialize with mock data
        self._init_mock_data()
    
    def _init_mock_data(self):
        """Initialize storage with mock data"""
        # Create a test user
        test_user = User(
            id=self.next_user_id,
            email="test@example.com",
            hashed_password=get_password_hash("password123"),
            first_name="Test",
            last_name="User",
            role=UserRole.PASSENGER,
            is_active=True,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        )
        self.users[self.next_user_id] = test_user
        self.users_by_email[test_user.email] = test_user
        self.next_user_id += 1
    
    # User operations
    def create_user(self, email: str, hashed_password: str, first_name: str, last_name: str) -> User:
        """Create a new user"""
        if email in self.users_by_email:
            raise ValueError(f"User with email {email} already exists")
        
        user = User(
            id=self.next_user_id,
            email=email,
            hashed_password=hashed_password,
            first_name=first_name,
            last_name=last_name,
            role=UserRole.PASSENGER,
            is_active=True,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        )
        
        self.users[self.next_user_id] = user
        self.users_by_email[email] = user
        self.next_user_id += 1
        return user
    
    def get_user_by_email(self, email: str) -> Optional[User]:
        """Get user by email"""
        return self.users_by_email.get(email)
    
    def get_user_by_id(self, user_id: int) -> Optional[User]:
        """Get user by ID"""
        return self.users.get(user_id)
    
    def authenticate_user(self, email: str, password: str) -> Optional[User]:
        """Authenticate user by email and password"""
        user = self.get_user_by_email(email)
        if not user or not user.is_active:
            return None
        if not verify_password(password, user.hashed_password):
            return None
        return user
    
    # Booking operations
    def create_booking(
        self, 
        user_id: int, 
        flight_id: int, 
        seat_numbers: List[str],
        payment_method: Optional[str] = None,
        passenger_info: Optional[List[dict]] = None
    ) -> Booking:
        """Create a new booking with specific seats and optional passenger details"""
        booking = Booking(
            id=self.next_booking_id,
            user_id=user_id,
            flight_id=flight_id,
            seat_numbers=seat_numbers,
            payment_method=payment_method,
            passenger_info=passenger_info
        )
        self.bookings[self.next_booking_id] = booking
        self.next_booking_id += 1
        return booking
    
    def get_user_bookings(self, user_id: int) -> List[Booking]:
        """Get all bookings for a user"""
        return [b for b in self.bookings.values() if b.user_id == user_id]


# Global mock storage instance
mock_storage = MockStorage()