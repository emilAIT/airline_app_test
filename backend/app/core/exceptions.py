"""
Custom exceptions for business logic errors.
All exceptions return consistent error format: {"detail": "...", "code": "..."}
"""
from fastapi import HTTPException, status


class ZaKuException(HTTPException):
    """
    Base exception for all business logic errors.
    
    Automatically returns consistent error format with detail and code.
    Subclasses should define their own status_code, detail, and code.
    """
    def __init__(self, detail: str, code: str, status_code: int = 400):
        super().__init__(status_code=status_code, detail={"detail": detail, "code": code})
        self.detail_text = detail
        self.code = code


# Authentication & Authorization Errors

class InvalidCredentials(ZaKuException):
    """Email or password is incorrect."""
    def __init__(self):
        super().__init__(
            detail="Invalid email or password",
            code="INVALID_CREDENTIALS",
            status_code=status.HTTP_401_UNAUTHORIZED
        )


class InvalidToken(ZaKuException):
    """JWT token is invalid or expired."""
    def __init__(self):
        super().__init__(
            detail="Invalid or expired token",
            code="INVALID_TOKEN",
            status_code=status.HTTP_401_UNAUTHORIZED
        )


class Forbidden(ZaKuException):
    """User doesn't have required permissions."""
    def __init__(self, required_role: str = None):
        detail = f"Access denied. Required role: {required_role}" if required_role else "Access denied"
        super().__init__(
            detail=detail,
            code="FORBIDDEN",
            status_code=status.HTTP_403_FORBIDDEN
        )


# Profile & Booking Errors

class ProfileIncomplete(ZaKuException):
    """User profile must be completed before booking."""
    def __init__(self):
        super().__init__(
            detail="Passenger profile must be completed before booking a flight",
            code="PROFILE_INCOMPLETE",
            status_code=status.HTTP_400_BAD_REQUEST
        )


class FlightNotBookable(ZaKuException):
    """Flight cannot be booked (CANCELLED, DEPARTED, or LANDED)."""
    def __init__(self, flight_status: str):
        super().__init__(
            detail=f"Flight is {flight_status} and cannot be booked",
            code="FLIGHT_NOT_BOOKABLE",
            status_code=status.HTTP_400_BAD_REQUEST
        )


class BookingExpired(ZaKuException):
    """Seat hold has expired (> 10 minutes without payment)."""
    def __init__(self):
        super().__init__(
            detail="Booking has expired. Seats were released after hold period.",
            code="BOOKING_EXPIRED",
            status_code=status.HTTP_400_BAD_REQUEST
        )


# Seat & Conflict Errors

class SeatAlreadyTaken(ZaKuException):
    """Seat is already held or booked by another user."""
    def __init__(self, seat_number: str):
        super().__init__(
            detail=f"Seat {seat_number} is already taken",
            code="SEAT_ALREADY_TAKEN",
            status_code=status.HTTP_409_CONFLICT
        )


class DuplicateResource(ZaKuException):
    """Resource already exists (e.g., email, flight number)."""
    def __init__(self, resource: str):
        super().__init__(
            detail=f"{resource} already exists",
            code="DUPLICATE_RESOURCE",
            status_code=status.HTTP_409_CONFLICT
        )


# Payment Errors

class PaymentFailed(ZaKuException):
    """Payment processing failed."""
    def __init__(self, reason: str = "Payment declined"):
        super().__init__(
            detail=reason,
            code="PAYMENT_FAILED",
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY
        )


# Not Found Errors

class NotFound(ZaKuException):
    """Resource not found."""
    def __init__(self, resource: str):
        super().__init__(
            detail=f"{resource} not found",
            code="NOT_FOUND",
            status_code=status.HTTP_404_NOT_FOUND
        )


class ValidationError(ZaKuException):
    """Data validation failed."""
    def __init__(self, detail: str):
        super().__init__(
            detail=detail,
            code="VALIDATION_ERROR",
            status_code=status.HTTP_400_BAD_REQUEST
        )
