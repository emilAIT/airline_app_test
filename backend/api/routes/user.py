from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from db.session import get_db
from models.user import User
from schemas.user import StaffCreate, UserResponse
from core.security import hash_password
from core.dependencies import require_admin

router = APIRouter(
    prefix="/users",
    tags=["Users"]
)

@router.post(
    "/staff",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED
)
def create_staff_user(
    data: StaffCreate,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    # Проверка на существование email
    existing_user = db.query(User).filter(
        User.email == data.email
    ).first()

    if existing_user:
        raise HTTPException(
            status_code=400,
            detail="User with this email already exists",
        )

    hashed_password = hash_password(data.password)

    staff = User.create_staff(
        db=db,
        email=data.email,
        hashed_password=hashed_password,
    )

    return staff
