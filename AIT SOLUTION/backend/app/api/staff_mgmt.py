from fastapi import APIRouter, Depends
from sqlmodel import Session
from typing import List
from app.database import get_session
from app.models import User
from app.core.deps import get_current_user
from app.services.all_services import UserService

router = APIRouter(prefix="/staff-management", tags=["staff-management"])

@router.get("/pending", response_model=List[User])
# Назначение: Список стаффа ожидающего подтверждения
# Принимает: текущего пользователя (должен быть админ)
# Возвращает: пользователей в статусе pending
def get_pending(
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    service = UserService(session)
    return service.get_pending_staff(current_user)

@router.post("/{user_id}/approve")
# Назначение: Подтвердить стаффа
# Принимает: user_id стаффа
# Возвращает: статус операции
def approve(
    user_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    service = UserService(session)
    return service.approve_staff(user_id, current_user)

@router.post("/{user_id}/reject")
# Назначение: Отклонить стаффа
# Принимает: user_id стаффа
# Возвращает: статус операции
def reject(
    user_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    service = UserService(session)
    return service.reject_staff(user_id, current_user)

@router.get("/summary")
# Назначение: Полный список USER/STAFF для администратора со статусами и привязками
# Принимает: текущего пользователя (админ)
# Возвращает: агрегированную сводку
def list_users_summary(
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    service = UserService(session)
    return service.get_all_users_summary(current_user)
