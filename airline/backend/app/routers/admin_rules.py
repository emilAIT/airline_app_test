from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.all_models import CancellationPolicy, User, UserRole
from app.schemas.schemas import CancellationPolicyCreate, CancellationPolicyOut
from app.auth.auth_handler import get_current_user
from typing import List

router = APIRouter(prefix="/admin/policy", tags=["Admin Cancellation Policy"])

# DEPENDENCY: Admin Only
def get_current_admin(current_user: User = Depends(get_current_user)):
    if current_user.role != UserRole.STAFF:
        raise HTTPException(
            status_code=403, detail="Not authorized. Staff access required.")
    return current_user


@router.get("/", response_model=CancellationPolicyOut)
@router.get("", response_model=CancellationPolicyOut)
def get_active_policy(
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    """Returns the currently active cancellation policy."""
    policy = db.query(CancellationPolicy).filter(CancellationPolicy.is_active == True).first()
    if not policy:
        raise HTTPException(status_code=404, detail="No active policy found")
    return policy


@router.post("/", response_model=CancellationPolicyOut, status_code=status.HTTP_201_CREATED)
@router.post("", response_model=CancellationPolicyOut, status_code=status.HTTP_201_CREATED)
def create_policy(
    policy_data: CancellationPolicyCreate,
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    """Create a new policy. If is_active=True, deactivates all other policies."""
    if policy_data.is_active:
        db.query(CancellationPolicy).update({CancellationPolicy.is_active: False})
    
    new_policy = CancellationPolicy(**policy_data.model_dump())
    db.add(new_policy)
    db.commit()
    db.refresh(new_policy)
    return new_policy


@router.put("/{policy_id}", response_model=CancellationPolicyOut)
def update_policy(
    policy_id: int,
    policy_data: CancellationPolicyCreate,
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    """Update an existing policy. If is_active=True, deactivates all other policies."""
    policy = db.query(CancellationPolicy).filter(CancellationPolicy.id == policy_id).first()
    if not policy:
        raise HTTPException(status_code=404, detail="Policy not found")
    
    if policy_data.is_active:
        db.query(CancellationPolicy).filter(CancellationPolicy.id != policy_id).update({CancellationPolicy.is_active: False})

    for key, value in policy_data.model_dump().items():
        setattr(policy, key, value)
    
    db.commit()
    db.refresh(policy)
    return policy


@router.delete("/{policy_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_policy(
    policy_id: int,
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    policy = db.query(CancellationPolicy).filter(CancellationPolicy.id == policy_id).first()
    if not policy:
        raise HTTPException(status_code=404, detail="Policy not found")
    
    db.delete(policy)
    db.commit()
    return None
