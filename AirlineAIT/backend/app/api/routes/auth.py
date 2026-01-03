"""
Authentication API routes.

Endpoints:
- POST /register: Register new user (PASSENGER or STAFF)
- POST /login: Login and get JWT token
- GET /me: Get current user info

Part of: Backend API Routes
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.schemas.auth import UserRegister, UserLogin, Token, UserResponse
from app.services.auth import create_user, authenticate_user, create_access_token_for_user
from app.models.user import User, UserRole
from app.api.deps import get_current_user

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register(user_data: UserRegister, db: Session = Depends(get_db)):
    """
    Register a new user (PASSENGER or STAFF)
    - PASSENGER: Regular user account
    - STAFF: Requires assigned_airplane_id (must be provided)
    """
    # Validate role
    requested_role = user_data.role.upper() if user_data.role else "PASSENGER"
    
    if requested_role not in ["PASSENGER", "STAFF"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid role. Must be 'PASSENGER' or 'STAFF'"
        )
    
    # Convert to enum
    role = UserRole.PASSENGER if requested_role == "PASSENGER" else UserRole.STAFF
    
    # Validate staff registration
    if role == UserRole.STAFF:
        # Staff registration no longer requires airplane assignment immediately
        # It will be assigned by admin during approval
        pass
    
    # Create user
    user = create_user(db, user_data, role=role, assigned_airplane_id=user_data.assigned_airplane_id if role == UserRole.STAFF else None)
    return user


@router.post("/login", response_model=Token)
def login(credentials: UserLogin, db: Session = Depends(get_db)):
    """Login and get access token"""
    user = authenticate_user(db, credentials.email, credentials.password)
    access_token = create_access_token_for_user(user)
    return {"access_token": access_token, "token_type": "bearer"}


@router.get("/me", response_model=UserResponse)
def get_current_user_info(current_user: User = Depends(get_current_user)):
    """Get current user information"""
    return current_user


@router.get("/debug-users")
def debug_users(db: Session = Depends(get_db)):
    """List all users for debugging (DEVELOPMENT ONLY)"""
    users = db.query(User).all()
    return [{
        "id": u.id,
        "email": u.email,
        "role": u.role,
        "is_active": u.is_active,
        "is_approved": u.is_approved
    } for u in users]


@router.get("/check-email/{email}")
def check_email(email: str, db: Session = Depends(get_db)):
    """Check if an email exists (for debugging)"""
    email_lower = email.lower().strip()
    from sqlalchemy import func
    existing_user = db.query(User).filter(
        func.lower(User.email) == email_lower
    ).first()
    
    all_users = db.query(User).all()
    user_details = []
    for u in all_users:
        user_details.append({
            "email": u.email,
            "role": u.role,
            "is_active": u.is_active,
            "is_approved": u.is_approved
        })
        
    return {
        "email_checked": email_lower,
        "exists": existing_user is not None,
        "total_users": len(all_users),
        "users": user_details
    }


@router.post("/promote-to-staff/{email}")
def promote_to_staff(email: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """
    Promote a user to staff role. 
    Note: In production, this should be restricted to existing staff/admin only.
    For now, any authenticated user can promote others (for development).
    """
    from sqlalchemy import func
    
    email_lower = email.lower().strip()
    user = db.query(User).filter(
        func.lower(User.email) == email_lower
    ).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    if user.role == UserRole.STAFF:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User is already a staff member"
        )
    
    user.role = UserRole.STAFF
    db.commit()
    db.refresh(user)
    
    return {
        "message": f"User {user.email} has been promoted to staff",
        "user": {
            "id": user.id,
            "email": user.email,
            "role": user.role.value
        }
    }

