"""
Admin-only API routes.

Endpoints:
- GET /staff/pending: List pending staff approvals
- GET /staff: List all staff members
- POST /staff/{id}/approve: Approve staff registration
- DELETE /staff/{id}/reject: Reject and delete pending staff
- DELETE /staff/{id}: Delete approved staff
- DELETE /users/{id}: Delete any user (staff or passenger)

Part of: Backend API Routes
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.db.session import get_db
from app.api.deps import get_current_admin, get_current_staff
from app.models.user import User, UserRole
from app.models.airport import Airport
from app.schemas.auth import UserResponse
from app.schemas.airport import AirportCreate, AirportUpdate, AirportResponse

router = APIRouter(prefix="/admin", tags=["Admin"])


# ==================== STAFF APPROVAL ====================

@router.get("/staff/pending", response_model=List[UserResponse])
def list_pending_staff(
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    """List all pending staff registrations (Admin only)"""
    pending_staff = db.query(User).filter(
        User.role == UserRole.STAFF,
        User.is_approved == False
    ).all()
    return pending_staff


@router.get("/staff", response_model=List[UserResponse])
def list_all_staff(
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    """List all staff members (Admin only)"""
    staff = db.query(User).filter(User.role == UserRole.STAFF).all()
    return staff


@router.post("/staff/{user_id}/approve")
def approve_staff(
    user_id: int,
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    """Approve a pending staff registration (Admin only)"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    if user.role != UserRole.STAFF:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User is not a staff member"
        )
    
    if user.is_approved:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Staff member is already approved"
        )
    
    user.is_approved = True
    # No airplane assignment needed for global staff
    db.commit()
    db.refresh(user)
    
    return {"message": f"Staff member {user.email} has been approved", "user_id": user.id}


@router.delete("/staff/{user_id}/reject")
def reject_staff(
    user_id: int,
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    """Reject a pending staff registration and delete the account (Admin only)"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    if user.role != UserRole.STAFF:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User is not a staff member"
        )
    
    if user.is_approved:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot reject an already approved staff member. Use delete instead."
        )
    
    email = user.email
    db.delete(user)
    db.commit()
    
    return {"message": f"Staff registration for {email} has been rejected"}


@router.delete("/staff/{user_id}")
def delete_staff(
    user_id: int,
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    """Delete a staff member (Admin only)"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    if user.role != UserRole.STAFF:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User is not a staff member"
        )
    
    if user.role == UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete admin users"
        )
    
    email = user.email
    db.delete(user)
    db.commit()
    
    return {"message": f"Staff member {email} has been deleted"}


@router.delete("/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user_universal(
    user_id: int,
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    """Delete any user (Staff or Passenger) (Admin only)"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    if user.role == UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete admin users"
        )
    
    from app.api.routes.staff import log_critical_action
    
    email = user.email
    user_role = user.role.value
    
    # Optional: Clean up associated data (profiles, etc. if not handled by cascade)
    # The database usually handles cascades if set up correctly in models
    
    db.delete(user)
    db.commit()
    
    log_critical_action(current_user, "DELETE_USER", "User", user_id, f"Email: {email}, Role: {user_role}")
    
    return None




