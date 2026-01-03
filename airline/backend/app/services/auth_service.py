from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.models.user import User, UserRole
from app.schemas.user import UserCreate, UserRegister
from app.core.security import get_password_hash, verify_password, create_access_token
from datetime import timedelta
from app.core.config import settings


def create_user(db: Session, user_data: UserCreate, role: UserRole = UserRole.PASSENGER) -> User:
    # Проверяем, существует ли пользователь
    db_user = db.query(User).filter(User.email == user_data.email).first()
    if db_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Этот email уже зарегистрирован"
        )
    
    try:
        hashed_password = get_password_hash(user_data.password)
        db_user = User(
            email=user_data.email,
            hashed_password=hashed_password,
            full_name=user_data.full_name,
            phone=user_data.phone,
            role=role
        )
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        return db_user
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Ошибка при создании пользователя: {str(e)}"
        )


def register_passenger(db: Session, user_data: UserRegister) -> User:
    # Проверяем обязательные поля для пассажира
    if not user_data.passport_number or not user_data.nationality or not user_data.date_of_birth:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Для пассажиров обязательны номер паспорта, гражданство и дата рождения"
        )
    
    try:
        # Создаём UserCreate из UserRegister для совместимости
        user_create = UserCreate(
            email=user_data.email,
            password=user_data.password,
            full_name=user_data.full_name,
            phone=user_data.phone
        )
        
        db_user = create_user(db, user_create, UserRole.PASSENGER)
        db_user.passport_number = user_data.passport_number
        db_user.nationality = user_data.nationality
        db_user.date_of_birth = user_data.date_of_birth
        db.commit()
        db.refresh(db_user)
        return db_user
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Ошибка при регистрации пассажира: {str(e)}"
        )


def authenticate_user(db: Session, email: str, password: str) -> User:
    user = db.query(User).filter(User.email == email).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Неверный email или пароль"
        )
    if not verify_password(password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Неверный email или пароль"
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Учетная запись пользователя неактивна"
        )
    return user


def create_access_token_for_user(user: User) -> str:
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.id, "role": user.role.value},
        expires_delta=access_token_expires
    )
    return access_token



