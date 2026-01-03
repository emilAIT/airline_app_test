"""
Authentication service - handles user registration and login.
"""
from sqlalchemy.orm import Session
from app.core.security import hash_password, verify_password, create_access_token
from app.core.exceptions import InvalidCredentials, DuplicateResource
from app.repositories.user import user_repository
from app.schemas.user import UserRegister, UserLogin, TokenResponse, UserResponse, UserRole


class AuthService:
    """
    Business logic for authentication.
    
    Handles:
        - User registration (PASSENGER only, STAFF created via seed/admin)
        - Login with email/password
        - JWT token generation
    """
    
    def register_passenger(self, db: Session, data: UserRegister) -> TokenResponse:
        """
        Register new passenger user.
        
        Only creates PASSENGER users. STAFF users are created via seed data.
        
        Raises:
            DuplicateResource: If email already exists
        """
        # Check if email already exists
        if user_repository.email_exists(db, data.email):
            raise DuplicateResource("Email")
        
        # Hash password
        hashed_pwd = hash_password(data.password)
        
        # Create user with PASSENGER role
        user = user_repository.create(
            db=db,
            email=data.email,
            hashed_password=hashed_pwd,
            role=UserRole.PASSENGER.value
        )
        
        db.commit()
        
        # Generate JWT token
        token = create_access_token(user.id, user.role)
        
        return TokenResponse(
            access_token=token,
            user=UserResponse.model_validate(user)
        )
    
    def login(self, db: Session, data: UserLogin) -> TokenResponse:
        """
        Authenticate user with email and password.
        
        Raises:
            InvalidCredentials: If email not found or password incorrect
        """
        # Find user by email
        user = user_repository.get_by_email(db, data.email)
        
        if not user:
            raise InvalidCredentials()
        
        # Verify password
        if not verify_password(data.password, user.hashed_password):
            raise InvalidCredentials()
        
        # Check if user is active
        if not user.is_active:
            raise InvalidCredentials()
        
        # Generate JWT token
        token = create_access_token(user.id, user.role)
        
        return TokenResponse(
            access_token=token,
            user=UserResponse.model_validate(user)
        )


# Singleton
auth_service = AuthService()
