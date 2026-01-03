"""
User repository - database operations for users.
"""
from typing import Optional
from sqlalchemy.orm import Session
from app.models.user import User


class UserRepository:
    """
    Data access layer for User model.
    Only handles CRUD operations, no business logic.
    """
    
    def create(self, db: Session, email: str, hashed_password: str, role: str) -> User:
        """Create новая запись User."""
        user = User(
            email=email.lower(),  # Normalize email to lowercase
            hashed_password=hashed_password,
            role=role
        )
        db.add(user)
        db.flush()  # Get ID without committing
        db.refresh(user)
        return user
    
    def get_by_id(self, db: Session, user_id: int) -> Optional[User]:
        """Find user by ID."""
        return db.query(User).filter(User.id == user_id).first()
    
    def get_by_email(self, db: Session, email: str) -> Optional[User]:
        """Find user by email (case-insensitive)."""
        return db.query(User).filter(User.email == email.lower()).first()
    
    def email_exists(self, db: Session, email: str) -> bool:
        """Check if email already exists."""
        return db.query(User).filter(User.email == email.lower()).count() > 0


# Singleton instance
user_repository = UserRepository()
